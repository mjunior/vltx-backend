# Roadmap: Marketplace Backend

## Milestones

- ✅ **v1.0 Milestone** — shipped 2026-03-06 (Phases 1-5). Archive: [.planning/milestones/v1.0-ROADMAP.md](./milestones/v1.0-ROADMAP.md)
- 🚧 **v1.1 Profile and Catalog** — in progress (Phases 6-10)

## Phases (v1.1)

- [ ] **Phase 6: Profile Self-Service and AuthZ Guardrails**
  - Goal: permitir edição do próprio perfil com bloqueio explícito de acesso cross-tenant.
  - Requirements: `PROF-03`, `AUTHZ-01`, `AUTHZ-04`
  - Success criteria:
    1. Usuário autenticado edita `name` e `address` do próprio perfil.
    2. Requisições sem auth válida são recusadas.
    3. Tentativas de editar perfil de outro usuário são bloqueadas.

- [ ] **Phase 7: Seller Product Creation (Owner Derived from Token)**
  - Goal: permitir criação de anúncios sem confiar em `owner_id/user_id` do frontend.
  - Requirements: `PROD-01`, `AUTHZ-03`
  - Success criteria:
    1. Vendedor autenticado cria anúncio com campos obrigatórios.
    2. Owner do produto é sempre derivado do token.
    3. Payload com `owner_id/user_id` não define ownership.

- [ ] **Phase 8: Seller Product Lifecycle (Edit/Deactivate/Delete)**
  - Goal: garantir que vendedor gerencie apenas anúncios próprios.
  - Requirements: `PROD-02`, `PROD-03`, `PROD-04`, `AUTHZ-02`
  - Success criteria:
    1. Vendedor edita apenas anúncios próprios.
    2. Vendedor desativa e deleta apenas anúncios próprios.
    3. Ações em anúncios de terceiros retornam negação autorizativa.

- [ ] **Phase 9: Public Product Listing with Search/Filter/Sort**
  - Goal: expor catálogo público eficiente sob namespace `/public`.
  - Requirements: `PUB-01`, `PUB-02`, `PUB-03`, `PUB-04`
  - Success criteria:
    1. `GET /public/products` retorna apenas produtos publicáveis.
    2. Busca textual funciona por termos relevantes.
    3. Filtro por faixa de preço e ordenação funcionam de forma determinística.

- [ ] **Phase 10: Public Product Detail and Safe Serialization**
  - Goal: expor detalhe público do produto com serializer dedicado e sem dados sensíveis.
  - Requirements: `PUB-05`, `PUB-06`
  - Success criteria:
    1. `GET /public/products/:id` retorna descrição, preço e estoque disponível.
    2. Serializer público não expõe campos sensíveis/internos.
    3. Contrato público permanece estável para consumo do frontend.

## Progress

| Phase | Milestone | Requirements | Status | Completed |
|-------|-----------|--------------|--------|-----------|
| 6. Profile Self-Service and AuthZ Guardrails | v1.1 | 3 | Not started | - |
| 7. Seller Product Creation (Owner Derived from Token) | v1.1 | 2 | Not started | - |
| 8. Seller Product Lifecycle (Edit/Deactivate/Delete) | v1.1 | 4 | Not started | - |
| 9. Public Product Listing with Search/Filter/Sort | v1.1 | 4 | Not started | - |
| 10. Public Product Detail and Safe Serialization | v1.1 | 2 | Not started | - |
