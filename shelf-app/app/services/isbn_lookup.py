import httpx
from typing import Optional

from app.config import settings
from app.models import BookLookupResult
from app.supabase_client import get_supabase_client

GOOGLE_BOOKS_URL = "https://www.googleapis.com/books/v1/volumes"
OPEN_LIBRARY_URL = "https://openlibrary.org/isbn/{isbn}.json"
OPEN_LIBRARY_AUTHOR_URL = "https://openlibrary.org{author_key}.json"
OPEN_LIBRARY_COVER_URL = "https://covers.openlibrary.org/b/isbn/{isbn}-L.jpg"


async def lookup_isbn(isbn: str) -> BookLookupResult:
    """
    Estratégia:
    1. Verifica se já existe no cache (tabela `books` no Supabase).
    2. Se não, consulta a Google Books API.
    3. Se não encontrar, consulta a Open Library API.
    4. Salva o resultado no cache para próximas consultas.
    """
    isbn = _normalize_isbn(isbn)

    cached = _get_from_cache(isbn)
    if cached:
        return cached

    result = await _lookup_google_books(isbn)
    if result is None:
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


async def _lookup_google_books(isbn: str) -> Optional[BookLookupResult]:
    params = {"q": f"isbn:{isbn}"}
    if settings.google_books_api_key:
        params["key"] = settings.google_books_api_key

    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            response = await client.get(GOOGLE_BOOKS_URL, params=params)
            response.raise_for_status()
            data = response.json()
        except (httpx.HTTPError, ValueError):
            return None

    items = data.get("items")
    if not items:
        return None

    volume_info = items[0].get("volumeInfo", {})
    image_links = volume_info.get("imageLinks", {})

    return BookLookupResult(
        isbn=isbn,
        title=volume_info.get("title", "Título não encontrado"),
        authors=volume_info.get("authors", []),
        publisher=volume_info.get("publisher"),
        published_date=volume_info.get("publishedDate"),
        page_count=volume_info.get("pageCount"),
        cover_url=image_links.get("thumbnail") or image_links.get("smallThumbnail"),
        description=volume_info.get("description"),
        source="google_books",
        found=True,
    )


async def _lookup_open_library(isbn: str) -> Optional[BookLookupResult]:
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            response = await client.get(OPEN_LIBRARY_URL.format(isbn=isbn))
            if response.status_code == 404:
                return None
            response.raise_for_status()
            data = response.json()
        except (httpx.HTTPError, ValueError):
            return None

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
