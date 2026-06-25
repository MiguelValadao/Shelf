from fastapi import APIRouter, HTTPException, Query

from app.models import BookLookupResult
from app.services.isbn_lookup import lookup_isbn

router = APIRouter(prefix="/api/books", tags=["books"])


@router.get("/lookup", response_model=BookLookupResult)
async def get_book_by_isbn(
    isbn: str = Query(..., min_length=8, max_length=20, description="ISBN-10 ou ISBN-13")
):
    """
    Busca os dados de um livro pelo ISBN.
    Ordem de busca: cache (Supabase) -> Open Library.
    """
    result = await lookup_isbn(isbn)
    if not result.found:
        detail = "Livro não encontrado para este ISBN. Cadastre manualmente."
        if result.error_message:
            detail = f"Não foi possível consultar o livro. {result.error_message}"
        raise HTTPException(status_code=404, detail=detail)
    return result
