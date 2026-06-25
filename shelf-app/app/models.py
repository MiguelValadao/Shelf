from typing import Optional
from pydantic import BaseModel


class BookLookupResult(BaseModel):
    isbn: str
    title: str
    authors: list[str] = []
    publisher: Optional[str] = None
    published_date: Optional[str] = None
    page_count: Optional[int] = None
    cover_url: Optional[str] = None
    description: Optional[str] = None
    source: str  # "open_library" | "cache"
    found: bool = True
    error_message: Optional[str] = None
