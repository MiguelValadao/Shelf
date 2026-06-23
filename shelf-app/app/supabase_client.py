from supabase import create_client, Client
from app.config import settings


def get_supabase_client() -> Client:
    """
    Cliente Supabase usando a SERVICE ROLE KEY.
    Usado apenas no backend para ler/gravar no catálogo `books`
    (cache de resultados de ISBN), ignorando RLS quando necessário.
    NUNCA exponha essa chave no Flutter.
    """
    return create_client(settings.supabase_url, settings.supabase_service_role_key)
