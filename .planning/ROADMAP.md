# Roadmap: Marketplace Backend

## Milestones

- ✅ **v1.0 Milestone** — shipped 2026-03-06 (Phases 1-5). Archive: [.planning/milestones/v1.0-ROADMAP.md](./milestones/v1.0-ROADMAP.md)
- 🚧 **v1.1 Profile and Catalog** — in progress (Phases 6-10)

## Phases (v1.1)

- [x] **Phase 6: Profile Self-Service and AuthZ Guardrails**
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

## Phase Details

### Phase 6: Profile Self-Service and AuthZ Guardrails
**Goal**: Permitir edição de perfil próprio com enforcement de autenticação e isolamento multi-tenant.
**Depends on**: Phase 5
**Requirements**: PROF-03, AUTHZ-01, AUTHZ-04
**Success Criteria** (what must be TRUE):
  1. Usuário autenticado edita `name` e `address` do próprio perfil.
  2. Requisições sem autenticação válida são recusadas.
  3. Tentativas de editar perfil de outro usuário são bloqueadas.
**Plans**: 2 plans

Plans:
- [x] 06-01: Implementar endpoint de atualização de perfil próprio
- [x] 06-02: Cobrir authz e cenários negativos de multi-tenant para perfil

### Phase 7: Seller Product Creation (Owner Derived from Token)
**Goal**: Permitir criação de anúncio sem aceitar ownership do frontend.
**Depends on**: Phase 6
**Requirements**: PROD-01, AUTHZ-03
**Success Criteria** (what must be TRUE):
  1. Vendedor autenticado cria anúncio com `title`, `description`, `price`, `stock_quantity`.
  2. Owner do produto é derivado exclusivamente do token.
  3. Campos `owner_id`/`user_id` do frontend não são aceitos para ownership.
**Plans**: 2 plans

Plans:
- [ ] 07-01: Criar model/serviço/controlador de criação de produto com owner pelo token
- [ ] 07-02: Cobrir validações de criação e bloqueio de payloads com owner forjado

### Phase 8: Seller Product Lifecycle (Edit/Deactivate/Delete)
**Goal**: Garantir que vendedor gerencie somente anúncios próprios.
**Depends on**: Phase 7
**Requirements**: PROD-02, PROD-03, PROD-04, AUTHZ-02
**Success Criteria** (what must be TRUE):
  1. Vendedor edita apenas anúncios que possui.
  2. Vendedor desativa e deleta apenas anúncios próprios.
  3. Operações sobre anúncios de terceiros são recusadas.
**Plans**: 3 plans

Plans:
- [ ] 08-01: Implementar update de produto com checagem de ownership
- [ ] 08-02: Implementar deactivate de produto com checagem de ownership
- [ ] 08-03: Implementar delete de produto com checagem de ownership

### Phase 9: Public Product Listing with Search/Filter/Sort
**Goal**: Expor listagem pública de produtos sob `/public/products` com consulta eficiente.
**Depends on**: Phase 8
**Requirements**: PUB-01, PUB-02, PUB-03, PUB-04
**Success Criteria** (what must be TRUE):
  1. `GET /public/products` lista produtos públicos/publicáveis.
  2. Busca textual, faixa de preço e ordenação funcionam conforme contrato.
  3. Endpoint não exige autenticação e não vaza dados sensíveis.
**Plans**: 2 plans

Plans:
- [ ] 09-01: Implementar endpoint público de listagem com filtros e ordenação
- [ ] 09-02: Adicionar testes de contrato público para busca/filtro/sort

### Phase 10: Public Product Detail and Safe Serialization
**Goal**: Expor detalhe público com serializer dedicado e seguro.
**Depends on**: Phase 9
**Requirements**: PUB-05, PUB-06
**Success Criteria** (what must be TRUE):
  1. `GET /public/products/:id` retorna descrição, preço e estoque disponível.
  2. Serializer público exclui informações sensíveis e internas.
  3. Contrato público de detalhe permanece estável para consumo frontend.
**Plans**: 2 plans

Plans:
- [ ] 10-01: Implementar endpoint público de detalhe de produto
- [ ] 10-02: Implementar serializer público específico e testes de não-vazamento

## Progress

| Phase | Milestone | Requirements | Status | Completed |
|-------|-----------|--------------|--------|-----------|
| 6. Profile Self-Service and AuthZ Guardrails | v1.1 | 3 | Complete | 2026-03-06 |
| 7. Seller Product Creation (Owner Derived from Token) | v1.1 | 2 | Planned | - |
| 8. Seller Product Lifecycle (Edit/Deactivate/Delete) | v1.1 | 4 | Not started | - |
| 9. Public Product Listing with Search/Filter/Sort | v1.1 | 4 | Not started | - |
| 10. Public Product Detail and Safe Serialization | v1.1 | 2 | Not started | - |
