from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import books

app = FastAPI(
    title="BookMory Clone - ISBN Lookup Service",
    description=(
        "Microserviço responsável apenas pela consulta de dados de livros "
        "por ISBN (Google Books / Open Library), com cache no Supabase. "
        "Todo o restante do CRUD é feito diretamente pelo Flutter no Supabase."
    ),
    version="1.0.0",
)

# Em produção, restrinja para o domínio/app real em vez de "*"
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

app.include_router(books.router)


@app.get("/health")
def health_check():
    return {"status": "ok"}
