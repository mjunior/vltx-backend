# Requirements: Marketplace Backend (v1.1)

**Defined:** 2026-03-06
**Milestone:** v1.1 Profile and Catalog
**Core Value:** Isolamento multi-tenant estrito com catálogo público seguro.

## v1.1 Requirements

### Profile

- [x] **PROF-03**: Usuário autenticado pode editar seu próprio perfil (`name`, `address`).

### Seller Products (Private)

- [ ] **PROD-01**: Vendedor autenticado pode criar anúncio com `title`, `description`, `price`, `stock_quantity`.
- [ ] **PROD-02**: Vendedor autenticado pode editar seus próprios anúncios.
- [ ] **PROD-03**: Vendedor autenticado pode desativar seus próprios anúncios.
- [ ] **PROD-04**: Vendedor autenticado pode deletar seus próprios anúncios.

### Public Catalog

- [ ] **PUB-01**: Sistema expõe listagem pública em `/public/products`.
- [ ] **PUB-02**: Listagem pública permite busca por texto (`title`/`description`).
- [ ] **PUB-03**: Listagem pública permite filtro por faixa de preço (`min_price`, `max_price`).
- [ ] **PUB-04**: Listagem pública permite ordenação configurável (ex.: preço asc/desc, mais recentes).
- [ ] **PUB-05**: Sistema expõe detalhe público em `/public/products/:id` com descrição, preço e estoque disponível.
- [ ] **PUB-06**: Endpoints públicos retornam apenas campos permitidos via serializer específico sem dados sensíveis.

### Security / Authorization

- [x] **AUTHZ-01**: Usuário não pode editar perfil de outro usuário.
- [ ] **AUTHZ-02**: Vendedor não pode criar/editar/desativar/deletar produto de outro vendedor.
- [ ] **AUTHZ-03**: Backend ignora/rejeita `user_id`, `owner_id` ou equivalentes enviados pelo frontend.
- [x] **AUTHZ-04**: Endpoints privados exigem usuário autenticado válido.

## Future Requirements

- MFA/2FA para contas sensíveis (SECV2-01)
- Gestão seletiva de sessões por dispositivo (SECV2-02)

## Out of Scope (v1.1)

| Feature | Reason |
|---------|--------|
| Checkout/pagamentos | Fora do escopo deste milestone |
| Upload complexo de mídia | Pode entrar após estabilizar CRUD e catálogo |
| Recomendação/ranqueamento avançado | Não necessário para v1.1 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROF-03 | Phase 6 | Complete |
| PROD-01 | Phase 7 | Planned |
| PROD-02 | Phase 8 | Planned |
| PROD-03 | Phase 8 | Planned |
| PROD-04 | Phase 8 | Planned |
| PUB-01 | Phase 9 | Planned |
| PUB-02 | Phase 9 | Planned |
| PUB-03 | Phase 9 | Planned |
| PUB-04 | Phase 9 | Planned |
| PUB-05 | Phase 10 | Planned |
| PUB-06 | Phase 10 | Planned |
| AUTHZ-01 | Phase 6 | Complete |
| AUTHZ-02 | Phase 8 | Planned |
| AUTHZ-03 | Phase 7 | Planned |
| AUTHZ-04 | Phase 6 | Complete |

**Coverage:**
- v1.1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-06 for milestone v1.1*
