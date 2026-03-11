# Requirements: Marketplace Backend

**Defined:** 2026-03-10
**Milestone:** v1.5 Admin Panel
**Core Value:** Isolamento multi-tenant estrito com contratos de autenticação e catálogo previsíveis.

## v1.5 Requirements

### Admin Authentication

- [x] **ADM-01**: Operador interno pode autenticar em rotas `/admin` usando uma entidade `Admin` separada de `User`.
- [x] **ADM-02**: Sessões administrativas usam JWT assinado e validado com secret dedicado, sem reutilizar o secret de usuário padrão.
- [x] **ADM-03**: Usuário padrão não consegue obter permissões administrativas por mutação de payload, perfil ou atributos da entidade `User`.

### User Verification and Moderation

- [x] **USR-01**: Sistema mantém status de verificação do usuário como `unverified` ou `verified` para uso administrativo e futura integração com OTP por e-mail.
- [x] **ADM-04**: Admin pode desativar qualquer usuário da plataforma sem depender de ownership buyer/seller.
- [x] **ADM-05**: Admin pode remover ou desativar anúncios inapropriados em escopo global.

### Admin Operations

- [x] **ADM-06**: Admin pode listar e inspecionar todos os pedidos da plataforma com escopo global.
- [x] **ADM-07**: Admin pode atualizar quaisquer dados de um usuário, incluindo foto, saldo e e-mail, por fluxo administrativo controlado.

### Admin Analytics

- [x] **ADM-08**: Admin pode visualizar dashboard com total de usuários, contagem de pedidos por status e volume financeiro do período informado.

### Contestation Resolution

- [x] **ADM-09**: Admin pode listar todas as contestações elegíveis para decisão operacional.
- [x] **ADM-10**: Admin pode negar ou aprovar uma contestação; quando aprovada, o comprador recebe refund seguro e idempotente.

## v2 Requirements

### Authentication

- **AUTH-05**: Admin pode usar MFA/2FA para endurecer login administrativo.
- **AUTH-06**: Usuário confirma e-mail por OTP e muda automaticamente para status `verified`.

### Payments

- **PAY-02**: Usuário ganha crédito promocional de R$ 10,00 somente após confirmação de e-mail.
- **PAY-06**: Seller pode solicitar saque ou liquidação externa do saldo a receber.
- **PAY-07**: Sistema suporta meios de pagamento externos como cartão e Pix.

### Orders and Ratings

- **ORD-08**: Workflow suporta mediação operacional completa da contestação com novos estados internos.
- **RATE-03**: Seller pode responder publicamente a avaliações recebidas e consultar médias agregadas.

## Out of Scope

| Feature | Reason |
|---------|--------|
| OTP/e-mail verification end-to-end | Este milestone entrega apenas a fundação de status para não misturar transporte de e-mail com painel admin |
| MFA para admin | Relevante, mas adiado para não atrasar a primeira superfície administrativa |
| Impersonação de usuário por admin | Aumenta risco operacional e não é necessária para moderação inicial |
| CRUD manual irrestrito de ledger | Ajuste de saldo admin deve continuar passando por regras financeiras controladas |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADM-01 | Phase 23 | Complete |
| ADM-02 | Phase 23 | Complete |
| ADM-03 | Phase 23 | Complete |
| USR-01 | Phase 23 | Complete |
| ADM-04 | Phase 24 | Complete |
| ADM-05 | Phase 24 | Complete |
| ADM-06 | Phase 24 | Complete |
| ADM-07 | Phase 25 | Complete |
| ADM-08 | Phase 26 | Complete |
| ADM-09 | Phase 27 | Complete |
| ADM-10 | Phase 27 | Complete |

**Coverage:**
- v1.5 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-10*
*Last updated: 2026-03-11 after Phase 27 Contestation Resolution Workflow*
