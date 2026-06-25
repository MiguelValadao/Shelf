import logging

import httpx
from typing import Optional

from app.models import BookLookupResult
from app.supabase_client import get_supabase_client

logger = logging.getLogger(__name__)

OPEN_LIBRARY_URL = "https://openlibrary.org/isbn/{isbn}.json"
OPEN_LIBRARY_AUTHOR_URL = "https://openlibrary.org{author_key}.json"
OPEN_LIBRARY_COVER_URL = "https://covers.openlibrary.org/b/isbn/{isbn}-L.jpg"


async def lookup_isbn(isbn: str) -> BookLookupResult:
    """
    Estratégia:
    1. Verifica se já existe no cache (tabela `books` no Supabase).
    2. Se não, consulta a Open Library API.
    3. Salva o resultado no cache para próximas consultas.
    """
    isbn = _normalize_isbn(isbn)

    cached = _get_from_cache(isbn)
    if cached:
        return cached

    result = await _lookup_open_library(isbn)

    if result is None:
        return BookLookupResult(isbn=isbn, title="", found=False, source="none")

    _save_to_cache(result)
    return result


def _normalize_isbn(isbn: str) -> str:
    return isbn.replace("-", "").replace(" ", "").strip()


def _get_from_cache(isbn: str) -> Optional[BookLookupResult]:
    try:
        supabase = get_supabase_client()
        response = (
            supabase.table("books")
            .select("*")
            .eq("isbn", isbn)
            .limit(1)
            .execute()
        )
        if response.data:
            row = response.data[0]
            return BookLookupResult(
                isbn=row["isbn"],
                title=row["title"],
                authors=row.get("authors") or [],
                publisher=row.get("publisher"),
                published_date=row.get("published_date"),
                page_count=row.get("page_count"),
                cover_url=row.get("cover_url"),
                description=row.get("description"),
                source="cache",
                found=True,
            )
    except Exception:
        # Se o cache falhar por qualquer motivo, simplesmente segue
        # para a busca nas APIs externas em vez de quebrar a requisição.
        pass
    return None


def _save_to_cache(result: BookLookupResult) -> None:
    try:
        supabase = get_supabase_client()
        supabase.table("books").upsert(
            {
                "isbn": result.isbn,
                "title": result.title,
                "authors": result.authors,
                "publisher": result.publisher,
                "published_date": result.published_date,
                "page_count": result.page_count,
                "cover_url": result.cover_url,
                "description": result.description,
                "source": result.source,
            },
            on_conflict="isbn",
        ).execute()
    except Exception:
        # Cache é "best effort" - não deve impedir a resposta ao usuário
        pass


async def _lookup_open_library(isbn: str) -> Optional[BookLookupResult]:
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            response = await client.get(OPEN_LIBRARY_URL.format(isbn=isbn))
            if response.status_code == 404:
                return None
            response.raise_for_status()
            data = response.json()
        except httpx.HTTPError as e:
            logger.error("HTTP error fetching ISBN %s from Open Library: %s", isbn, e)
            return BookLookupResult(
                isbn=isbn, title="", found=False, source="open_library",
                error_message=f"Erro HTTP ao consultar Open Library: {e}",
            )
        except ValueError as e:
            logger.error("Invalid response for ISBN %s from Open Library: %s", isbn, e)
            return BookLookupResult(
                isbn=isbn, title="", found=False, source="open_library",
                error_message=f"Resposta inválida da Open Library: {e}",
            )

        authors = []
        for author_ref in data.get("authors", []):
            author_key = author_ref.get("key")
            if not author_key:
                continue
            try:
                author_response = await client.get(
                    OPEN_LIBRARY_AUTHOR_URL.format(author_key=author_key)
                )
                if author_response.status_code == 200:
                    authors.append(author_response.json().get("name", ""))
            except httpx.HTTPError:
                continue

    title = data.get("title", "Título não encontrado")
    description = data.get("description")
    if isinstance(description, dict):
        description = description.get("value")

    return BookLookupResult(
        isbn=isbn,
        title=title,
        authors=[a for a in authors if a],
        publisher=", ".join(data.get("publishers", [])) or None,
        published_date=data.get("publish_date"),
        page_count=data.get("number_of_pages"),
        cover_url=OPEN_LIBRARY_COVER_URL.format(isbn=isbn),
        description=description,
        source="open_library",
        found=True,
    )
