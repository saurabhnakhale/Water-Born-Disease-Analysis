# NMC ADD & Water-Borne Disease Surveillance Dashboard

Interactive Epidemiological Intelligence Dashboard for the **Nagpur Municipal Corporation (NMC)** Health Department analyzing **Acute Diarrhoeal Disease (ADD)**, Gastroenteritis, Hepatitis A, Cholera, Typhoid, and Municipal Water Quality Testing across all 10 administrative zones (July 2025 – August 2026).

---

## 🌟 Overview & Key Metrics

- **511 Admitted Clinical Cases**: Categorized across Acute Gastroenteritis (AGE - 65.9%), Acute Diarrhoeal Disease (ADD - 21.7%), Hepatitis A (5.5%), Typhoid (2.7%), and Cholera (1.8%).
- **5 Confirmed Epidemic Outbreaks**: Mapped with GPS coordinates & direct Google Maps routing links.
- **17 Water-Borne Field Disease Events**: Alert notifications for Cholera & Hepatitis A clusters.
- **523 Water Quality Samples Tested**: 76 Non-Potable / Contaminated (14.5% overall fail rate; monsoon peak hit 44.4% in Aug 2025).
- **94 High-Risk Slum Settlements**: Geocoded with exact latitude/longitude coordinates across all 10 zones.

---

## 📊 Dashboard Capabilities

1. **Executive Overview**: Live KPI stat cards, dual-axis case incidence vs water contamination (%) correlation, diagnosis donut chart, and zone caseload ranking.
2. **Clinical Trends & Demographics**: Monthly diagnosis stacked trajectories, age cohort pyramid (Male vs Female), and facility admissions velocity.
3. **Zonewise Risk Analysis**: Zone Risk Vulnerability Matrix cross-referencing cases, water testing failure rate, slum density, and outbreaks.
4. **Water Quality Lab Hub**: Potable vs non-potable monthly breakdown and zone contamination leaderboard.
5. **GIS Interactive Field Map (Leaflet.js)**: Multi-layer map toggling Outbreaks (radar pulsing pins), Disease Events, and 94 High-Risk Areas with quick-zone focus.
6. **Case Linelist Explorer**: Searchable, filterable table for all 511 records with instant CSV download.

---

## 🚀 How to Run Locally

### Option 1: Direct File Launch
Simply double click or open `index.html` in any web browser (Chrome, Edge, Firefox). No build tools or backend servers required.

### Option 2: Local HTTP Server (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File .\serve.ps1 -Port 8085
```
Then navigate to: `http://localhost:8085/`

---

## 📁 Repository Structure
```
├── index.html            # Main interactive dashboard application
├── data.js               # Clean surveillance dataset bundle (511 cases, GIS, water samples)
├── clean_data.json       # Structured JSON dataset across all 5 sheets
├── serve.ps1             # Local lightweight HTTP server
├── .gitignore            # Git ignore file for temporary scripts
└── README.md             # Project documentation
```
