# Veilig Online — phishing-trainingstool

Een eenvoudige Nederlandstalige webapplicatie die mensen met beperkte digitale
vaardigheden helpt om phishing te herkennen. Met grote tekst, hoog contrast,
duidelijke voorbeelden (bank, Belastingdienst, PostNL, WhatsApp-truc, …) en
een korte oefenquiz.

- **Frontend**: statische HTML/CSS/JS (vanilla, geen build-stap).
- **Backend**: Node.js + Express.
- **Database**: PostgreSQL (gehost op [Neon](https://neon.tech)).
- **Hosting**: Web Service op [Render](https://render.com).

## Mappenstructuur

```
.
├── public/             ← statische frontend (index.html, css/, js/)
├── routes/api.js       ← REST endpoints
├── db/
│   ├── index.js        ← pg-pool
│   ├── schema.sql      ← tabellen
│   └── seed.sql        ← Nederlandse voorbeeld- en quizdata
├── scripts/init-db.js  ← past schema toe en zaait data
├── server.js           ← Express server
├── render.yaml         ← Render Blueprint
└── package.json
```

## Lokaal draaien

```bash
npm install
cp .env.example .env       # vul DATABASE_URL in (Neon)
npm run db:init            # eenmalig: tabellen + seed
npm run dev                # http://localhost:3000
```

## Database op Neon aanmaken

1. Ga naar <https://neon.tech>, maak een gratis project aan in regio
   `eu-central-1` (Frankfurt) voor lage latency vanuit NL.
2. Kopieer de **pooled connection string** (eindigt op `?sslmode=require`).
3. Zet deze in `.env` als `DATABASE_URL`, of als secret op Render.
4. Voer de schema- en seedscripts uit:

   ```bash
   npm run db:init
   ```

   Dit maakt de tabellen aan en laadt 10 quizvragen + 3 geannoteerde
   voorbeelden. Standaard zaait het alleen wanneer er nog geen vragen zijn;
   gebruik `node scripts/init-db.js --force-seed` om te overschrijven.

## Deployen op Render

### Optie A — via de Blueprint (`render.yaml`)

1. Push de repo naar GitHub.
2. Op Render: **New + → Blueprint** en selecteer de repo.
3. Render maakt de service automatisch aan met onderstaande instellingen.
4. Vul daarna in het dashboard de secret `DATABASE_URL` in (Neon-string).

### Optie B — handmatig "New + → Web Service"

| Instelling | Waarde |
|---|---|
| **Language / Runtime** | Node |
| **Build Command** | `npm install` |
| **Start Command** | `npm start` |
| **Health Check Path** | `/api/health` |
| **Environment variable** | `DATABASE_URL` = Neon connection string |
| **Environment variable** | `NODE_VERSION` = `20` |

Na de eerste deploy: open op Render de **Shell** van de service en draai
eenmalig `npm run db:init` om de tabellen aan te maken en te zaaien
(niet meer nodig bij latere deploys).

## API

| Methode | Pad | Doel |
|---|---|---|
| `GET`  | `/api/health` | Health check (DB-tijd) |
| `GET`  | `/api/examples` | Lijst geannoteerde voorbeelden |
| `GET`  | `/api/quiz?limit=5` | Random quizvragen |
| `POST` | `/api/attempts` | Start een nieuwe poging |
| `POST` | `/api/attempts/:id/answers` | Antwoord opslaan |
| `POST` | `/api/attempts/:id/finish` | Poging afsluiten |
| `GET`  | `/api/stats` | Geanonimiseerde geaggregeerde statistieken |

Het `session_id` wordt anoniem in `localStorage` opgeslagen — er worden
geen e-mailadressen of namen verzameld.

## Licentie

Gebruik vrij voor educatieve doeleinden.
