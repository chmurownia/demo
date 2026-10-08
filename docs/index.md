# Chmurownia — Demo 🚀

<script>
  (function(n,i,v,r,s,c,x,z){x=window.AwsRumClient={q:[],n:n,i:i,v:v,r:r,c:c};window[n]=function(c,p){x.q.push({c:c,p:p});};z=document.createElement('script');z.async=true;z.src=s;document.head.insertBefore(z,document.head.getElementsByTagName('script')[0]);})(
    'cwr',
    '700d9ab0-5773-4bd5-b017-dc03f3481e8d',
    '1.0.0',
    'eu-north-1',
    'https://client.rum.us-east-1.amazonaws.com/1.19.0/cwr.js',
    {
      sessionSampleRate: 1 ,
      identityPoolId: "eu-north-1:04b63099-d41e-4957-9aca-5781e9c2e8f1" ,
      endpoint: "https://dataplane.rum.eu-north-1.amazonaws.com" ,
      telemetries: ["performance","errors","http"] ,
      allowCookies: true ,
      enableXRay: false ,
      signing: false // If you have a public resource policy and wish to send unsigned requests please set this to false
    }
  );
</script>

Witaj! To jest **przykładowy efekt warsztatów** *"Praktyczne wprowadzenie do chmury AWS i pracy zespołowej w IT"*.

Cała ta strona jest zbudowana w **MkDocs**, przechowywana na **Amazon S3**, serwowana przez **CloudFront** (HTTPS + własna domena), a **Księga Gości** działa na żywo dzięki **API Gateway**, **AWS Lambda** i **DynamoDB**.

Co najważniejsze — **nie klikałem niczego ręcznie w konsoli AWS**. Cała infrastruktura powstała z kodu (**Terraform**), a publikacja odbywa się automatycznie przez **GitHub Actions** (CI/CD) z uwierzytelnieniem **OIDC** (bez kluczy dostępowych).

## Co uczniowie zbudują na warsztatach

- ✅ Statyczną stronę WWW (wizytówkę zespołu)
- ✅ Hosting na Amazon S3 + dystrybucja przez CloudFront
- ✅ Certyfikat HTTPS (ACM) i własną domenę (Route 53)
- ✅ Automatyczne wdrożenia z GitHub Actions (OIDC, bez kluczy)
- ✅ Dynamiczną Księgę Gości (API Gateway + Lambda + DynamoDB)

## Architektura rozwiązania

Poniższy diagram pokazuje, jak połączone są wszystkie elementy tego demo.

![Architektura rozwiązania](architektura.svg#only-light)
![Architektura rozwiązania](architektura-motyw.svg#only-dark)

## Użyte usługi AWS

| Usługa | Rola w projekcie |
|---|---|
| **Amazon S3** | Przechowuje pliki wygenerowanej strony |
| **Amazon CloudFront** | CDN + HTTPS, serwuje stronę użytkownikom |
| **AWS Certificate Manager** | Certyfikat TLS dla `demo.chmurownia.org` |
| **Amazon Route 53** | Rekord DNS wskazujący na CloudFront |
| **Amazon API Gateway** | Publiczne API Księgi Gości |
| **AWS Lambda** | Logika zapisu/odczytu wpisów |
| **Amazon DynamoDB** | Baza danych wpisów |
| **AWS IAM + OIDC** | Bezpieczne wdrożenia z GitHub Actions |

!!! tip "Dla nauczycieli"
    Każdy zespół uczniowski przechodzi dokładnie tę samą ścieżkę — od pustego repozytorium do w pełni działającej, automatycznie wdrażanej aplikacji w chmurze.
