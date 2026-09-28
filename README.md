# Chmurownia — Demo

Przykładowy efekt warsztatów *"Praktyczne wprowadzenie do chmury AWS"*, wdrożony w pełni z kodu (IaC + CI/CD). Strona: **[demo.chmurownia.org](https://demo.chmurownia.org)**.

To repozytorium pokazuje nauczycielom, co uczniowie zbudują: statyczną stronę WWW (MkDocs) na S3 + CloudFront z HTTPS i własną domeną, oraz dynamiczną Księgę Gości (API Gateway + Lambda + DynamoDB). Wszystko powstaje przez Terraform, a publikacja odbywa się automatycznie przez GitHub Actions z uwierzytelnieniem OIDC (bez kluczy dostępowych).

## Struktura

```
demo/
├── docs/                       # Treść strony (MkDocs, 4 podstrony)
│   ├── index.md                # Opis projektu + diagram architektury (Mermaid)
│   ├── cv.md                   # CV
│   ├── james-kiro.md           # Wyimaginowany asystent
│   └── ksiega.md               # Księga Gości (JS + fetch do API)
├── mkdocs.yml                  # Konfiguracja MkDocs Material
├── requirements.txt            # mkdocs-material
├── lambda/
│   └── guestbook/handler.py    # Lambda Księgi Gości (GET/POST /entries)
├── terraform/                  # Cała infrastruktura AWS
│   ├── versions.tf providers.tf variables.tf data.tf outputs.tf
│   ├── s3.tf                   # Bucket + polityka OAC
│   ├── acm.tf                  # Certyfikat TLS (us-east-1) + walidacja DNS
│   ├── cloudfront.tf           # Dystrybucja CloudFront + rekordy Route 53
│   ├── guestbook.tf            # DynamoDB + Lambda + HTTP API Gateway
│   └── github_oidc.tf          # OIDC provider + rola/polityka dla GitHub Actions
├── aws/                        # Referencyjne pliki JSON (dla porównania — infra tworzy Terraform)
└── .github/workflows/deploy.yml
```

## Konfiguracja (dane demo)

| Parametr | Wartość |
|---|---|
| Konto AWS | `727329303802` |
| Region | `eu-north-1` (Sztokholm) |
| Domena | `demo.chmurownia.org` |
| Hosted Zone ID | `Z07977711BCKZWIPUNYAP` |
| Repozytorium | `CHMUROWNIA/demo` |

Wartości można nadpisać w `terraform/variables.tf` lub przez `-var`.

## Wdrożenie — krok po kroku

### 1. Utwórz bucket na stan Terraform (jednorazowo)

```bash
aws s3api create-bucket \
  --bucket chmurownia-demo-tfstate \
  --region eu-north-1 \
  --create-bucket-configuration LocationConstraint=eu-north-1
aws s3api put-bucket-versioning \
  --bucket chmurownia-demo-tfstate \
  --versioning-configuration Status=Enabled
```

### 2. Zbuduj infrastrukturę

```bash
cd terraform
terraform init
terraform apply
```

Terraform utworzy: bucket S3, certyfikat ACM (z walidacją DNS w Route 53), dystrybucję CloudFront, rekordy A/AAAA, DynamoDB, Lambdę, API Gateway, OIDC provider oraz rolę IAM dla GitHub Actions.

> Pierwszy `apply` może potrwać kilka–kilkanaście minut — CloudFront i walidacja certyfikatu potrzebują czasu na propagację.

### 3. Ustaw zmienne repozytorium GitHub

W **Settings → Secrets and variables → Actions → Variables** dodaj (wartości z `terraform output`):

| Zmienna | Źródło (Terraform output) |
|---|---|
| `AWS_ROLE_ARN` | `github_actions_role_arn` |
| `AWS_REGION` | `eu-north-1` |
| `SITE_BUCKET` | `site_bucket_name` |
| `CLOUDFRONT_DISTID` | `cloudfront_distribution_id` |
| `GUESTBOOK_API_ENDPOINT` | `guestbook_api_endpoint` |

### 4. Wypchnij zmiany

```bash
git push origin main
```

GitHub Actions zbuduje stronę, wstrzyknie adres API Księgi Gości, wgra pliki na S3 i unieważni cache CloudFront. Po chwili strona jest dostępna pod `https://demo.chmurownia.org`.

## Jak działa Księga Gości

- **API contract:** `GET /entries` zwraca listę `{author, message, timestamp}` (najnowsze pierwsze); `POST /entries` przyjmuje `{author, message}`.
- Frontend (`docs/ksiega.md`) zawiera placeholder `__API_URL__`, który workflow podmienia na prawdziwy endpoint podczas budowania. Dzięki temu URL nie jest zapisany w repozytorium.
- Treść wpisów jest escapowana po stronie przeglądarki (ochrona przed XSS), a długość pól ograniczana po stronie Lambdy.

## Uwaga o plikach w `aws/`

Pliki `aws/GitHubActionsRole-trust.json` i `aws/GitHubActionsRole-policy.json` są **referencyjne** — pokazują, jak wyglądałaby konfiguracja robiona ręcznie (tak jak robią to uczniowie na warsztatach). W tym demo tożsamą rolę, politykę i OIDC provider tworzy Terraform (`github_oidc.tf`), więc to on jest źródłem prawdy.

## Uwaga o formacie `sub` (immutable subject claims)

To repozytorium powstało po 15 lipca 2026, więc GitHub używa „niezmiennego" formatu identyfikatora OIDC z numerycznymi ID organizacji i repozytorium:

```
repo:chmurownia@331737546/demo@1391044409:environment:demo
```

Polityka zaufania roli IAM (`github_oidc.tf`) dopasowuje dokładnie ten `sub`. Numeryczne ID są ustawione jako zmienne `github_org_id` i `github_repo_id`. Użycie starego formatu (`repo:org/repo:*`) kończy się błędem `Not authorized to perform sts:AssumeRoleWithWebIdentity`.

Workflow ustawia `environment: demo`, dlatego `sub` zawiera `:environment:demo` — zaufanie jest ograniczone tylko do wdrożeń z tego środowiska.

## Uwaga o thumbprint OIDC

Od lipca 2023 AWS weryfikuje endpoint OIDC GitHuba na podstawie własnej biblioteki zaufanych CA, więc thumbprint nie jest już używany do walidacji. Pole `thumbprint_list` pozostaje wymagane przez API, dlatego podana jest znana wartość GitHuba jako wypełnienie schematu.
