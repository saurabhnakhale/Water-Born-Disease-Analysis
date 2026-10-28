// Live Client-side Synchronizer for Google Sheets
// Base Sheet URL: https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub

window.GoogleSheetLiveSync = (function() {
  const SHEET_URLS = {
    linelist: "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=0&single=true&output=csv",
    waterSample: "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=246840870&single=true&output=csv",
    highRiskArea: "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=893083487&single=true&output=csv",
    event: "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=1177415409&single=true&output=csv",
    outbreak: "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=1614269266&single=true&output=csv"
  };

  const ZONE_NAMES = {
    "Zone 1": "Laxmi Nagar",
    "Zone 2": "Dharampeth",
    "Zone 3": "Hanuman Nagar",
    "Zone 4": "Dhantoli",
    "Zone 5": "Nehru Nagar",
    "Zone 6": "Gandhibagh",
    "Zone 7": "Satranjipura",
    "Zone 8": "Lakadganj",
    "Zone 9": "Ashi Nagar",
    "Zone 10": "Mangalwari",
    "Rural": "Rural / Non-NMC",
    "Other": "Other Districts/States"
  };

  const MONTH_MAP = {
    "2025-07": "Jul 2025",
    "2025-08": "Aug 2025",
    "2025-09": "Sep 2025",
    "2025-10": "Oct 2025",
    "2025-11": "Nov 2025",
    "2025-12": "Dec 2025",
    "2026-01": "Jan 2026",
    "2026-02": "Feb 2026",
    "2026-03": "Mar 2026",
    "2026-04": "Apr 2026",
    "2026-05": "May 2026",
    "2026-06": "Jun 2026",
    "2026-07": "Jul 2026",
    "2026-08": "Aug 2026",
    "2026-09": "Sep 2026"
  };

  function parseCSV(text) {
    const lines = [];
    let row = [""];
    let inQuotes = false;
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      const next = text[i + 1];
      if (c === '"') {
        if (inQuotes && next === '"') {
          row[row.length - 1] += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c === ',' && !inQuotes) {
        row.push("");
      } else if ((c === '\r' || c === '\n') && !inQuotes) {
        if (c === '\r' && next === '\n') i++;
        lines.push(row);
        row = [""];
      } else {
        row[row.length - 1] += c;
      }
    }
    if (row.length > 1 || row[0] !== "") lines.push(row);
    return lines;
  }

  function standardizeDiagnosis(d) {
    if (!d) return "Other / Non-specific";
    const s = d.toString().trim();
    if (/Gastroentr|Gastronetritis/i.test(s)) return "Acute Gastroenteritis (AGE)";
    if (/Diarrho|Loose motion/i.test(s)) return "Acute Diarrhoeal Disease (ADD)";
    if (/Hepatit/i.test(s)) return "Hepatitis A";
    if (/Cholera/i.test(s)) return "Cholera";
    if (/Typhoid|Tyhoid|Enteric Fever/i.test(s)) return "Typhoid / Enteric Fever";
    if (/Dysentry/i.test(s)) return "Dysentery";
    return "Other / Non-specific";
  }

  function standardizeZone(z) {
    if (!z) return "Unknown";
    const s = z.toString().trim();
    const m = s.match(/Zone\s*(\d+)/i);
    if (m) return "Zone " + m[1];
    if (/Rural/i.test(s)) return "Rural / Non-NMC";
    if (/Other/i.test(s)) return "Other Districts/States";
    return s;
  }

  function parseCustomDate(str) {
    if (!str) return null;
    const s = str.trim();
    if (!s) return null;
    const parts = s.split(/[\/\-]/);
    if (parts.length === 3) {
      let m = parseInt(parts[0], 10);
      let d = parseInt(parts[1], 10);
      let y = parseInt(parts[2], 10);
      // Check if day/month might be inverted or yyyy-mm-dd
      if (parts[0].length === 4) {
        y = parseInt(parts[0], 10);
        m = parseInt(parts[1], 10);
        d = parseInt(parts[2], 10);
      }
      if (y < 100) y += 2000;
      if (!isNaN(y) && !isNaN(m) && !isNaN(d) && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        const dt = new Date(Date.UTC(y, m - 1, d));
        return isNaN(dt.getTime()) ? null : dt;
      }
    }
    const dVal = new Date(s);
    return isNaN(dVal.getTime()) ? null : dVal;
  }

  function formatMonthKey(dt, rawMonth) {
    if (dt) {
      const y = dt.getUTCFullYear();
      const m = String(dt.getUTCMonth() + 1).padStart(2, '0');
      return `${y}-${m}`;
    }
    if (!rawMonth) return "";
    const s = rawMonth.toString().trim().toLowerCase();
    if (/jul.*25/.test(s)) return "2025-07";
    if (/aug.*25/.test(s)) return "2025-08";
    if (/sep.*25|september/.test(s)) return "2025-09";
    if (/oct.*25|october/.test(s)) return "2025-10";
    if (/nov.*25|november/.test(s)) return "2025-11";
    if (/dec.*25|december/.test(s)) return "2025-12";
    if (/jan.*26|january/.test(s)) return "2026-01";
    if (/feb.*26|february/.test(s)) return "2026-02";
    if (/mar.*26|march/.test(s)) return "2026-03";
    if (/apr.*26|april/.test(s)) return "2026-04";
    if (/may.*26|may/.test(s)) return "2026-05";
    if (/jun.*26|june/.test(s)) return "2026-06";
    if (/jul.*26|july/.test(s)) return "2026-07";
    if (/aug.*26|august/.test(s)) return "2026-08";
    if (/sep.*26/.test(s)) return "2026-09";
    return rawMonth;
  }

  function formatMonthLabel(mKey) {
    return MONTH_MAP[mKey] || mKey;
  }

  async function fetchCSV(url) {
    // Add cache busting param to always get the real latest state from Google Sheets CDN
    const bustUrl = url + (url.includes('?') ? '&' : '?') + '_ts=' + Date.now();
    const res = await fetch(bustUrl, { cache: 'no-cache' });
    if (!res.ok) throw new Error(`HTTP ${res.status} fetching ${url}`);
    return await res.text();
  }

  async function fetchLiveGoogleSheetData() {
    const [linelistCsv, waterCsv, hraCsv, eventCsv, outbreakCsv] = await Promise.all([
      fetchCSV(SHEET_URLS.linelist),
      fetchCSV(SHEET_URLS.waterSample),
      fetchCSV(SHEET_URLS.highRiskArea),
      fetchCSV(SHEET_URLS.event),
      fetchCSV(SHEET_URLS.outbreak)
    ]);

    // 1. Process Linelist
    const linelistRows = parseCSV(linelistCsv);
    const linelistHeaders = linelistRows[0].map(h => (h || '').trim());
    const hSr = linelistHeaders.indexOf('Sr No');
    const hMonth = linelistHeaders.indexOf('Month');
    const hZone = linelistHeaders.indexOf('Zone');
    const hName = linelistHeaders.indexOf('Name of Patient');
    const hAge = linelistHeaders.indexOf('Age');
    const hSex = linelistHeaders.indexOf('M/F');
    const hAdm = linelistHeaders.indexOf('Date of Admission');
    const hMob = linelistHeaders.indexOf('Mob No');
    const hAddr = linelistHeaders.indexOf('Address');
    const hDiag = linelistHeaders.indexOf('Diagnosis');
    const hHosp = linelistHeaders.indexOf('Hospital');

    const linelist = [];
    for (let i = 1; i < linelistRows.length; i++) {
      const r = linelistRows[i];
      const sr = (r[hSr] || '').trim();
      const name = (r[hName] || '').trim();
      if (!sr && !name) continue;

      const admDt = parseCustomDate(r[hAdm]);
      const mKey = formatMonthKey(admDt, r[hMonth]);
      const mLabel = formatMonthLabel(mKey);
      const z = standardizeZone(r[hZone]);
      const zName = ZONE_NAMES[z] || z;
      const diagCat = standardizeDiagnosis(r[hDiag]);

      let ageVal = null;
      if (hAge !== -1 && r[hAge]) {
        const parsedAge = parseInt(r[hAge].trim(), 10);
        if (!isNaN(parsedAge)) ageVal = parsedAge;
      }

      let gender = (r[hSex] || '').trim().toUpperCase();
      if (gender !== 'M' && gender !== 'F') gender = 'Other';

      linelist.push({
        id: sr || String(i),
        monthKey: mKey,
        month: mLabel,
        admissionDate: admDt ? admDt.toISOString().slice(0, 10) : '',
        zone: z,
        zoneName: zName,
        name: name || 'Unknown',
        age: ageVal,
        gender: gender,
        mobile: (r[hMob] || '').trim(),
        address: (r[hAddr] || '').trim(),
        rawDiagnosis: (r[hDiag] || '').trim(),
        diagnosisCategory: diagCat,
        hospital: (r[hHosp] || '').trim() || 'Isolation Hospital'
      });
    }

    // 2. Process High Risk Areas
    const hraRows = parseCSV(hraCsv);
    const hra = [];
    let currZ = "";
    let currZN = "";
    let hraIdx = 1;

    for (let i = 1; i < hraRows.length; i++) {
      const r = hraRows[i];
      const zVal = (r[1] || '').trim();
      const znVal = (r[2] || '').trim();
      if (zVal) currZ = standardizeZone(zVal);
      if (znVal) currZN = znVal;
      if (!currZN && ZONE_NAMES[currZ]) currZN = ZONE_NAMES[currZ];

      const area = (r[3] || '').trim();
      const prabhag = (r[4] || '').trim();
      const latlong = (r[5] || '').trim();

      if (!area && !latlong) continue;

      let lat = null, lng = null;
      const llMatch = latlong.match(/([0-9\.\-]+)\s*,\s*([0-9\.\-]+)/);
      if (llMatch) {
        lat = parseFloat(llMatch[1]);
        lng = parseFloat(llMatch[2]);
      }

      hra.push({
        id: hraIdx++,
        zone: currZ,
        zoneName: currZN,
        area: area,
        prabhag: prabhag,
        lat: lat,
        lng: lng,
        latlong: latlong,
        type: "High Risk Area (HRA)"
      });
    }

    // 3. Process Events
    const eventRows = parseCSV(eventCsv);
    let eventHeaderIdx = 0;
    for (let i = 0; i < eventRows.length; i++) {
      if (eventRows[i][0] && eventRows[i][0].trim() === 'Sr No') {
        eventHeaderIdx = i;
        break;
      }
    }
    const events = [];
    for (let i = eventHeaderIdx + 1; i < eventRows.length; i++) {
      const r = eventRows[i];
      const sr = (r[0] || '').trim();
      if (!sr) continue;

      const rawM = (r[1] || '').trim();
      const mKey = formatMonthKey(null, rawM);
      const mLabel = formatMonthLabel(mKey);
      const z = standardizeZone(r[3]);
      const zName = (r[2] || '').trim() || ZONE_NAMES[z] || z;
      const latlong = (r[7] || '').trim();

      let lat = null, lng = null;
      const llMatch = latlong.match(/([0-9\.\-]+)\s*,\s*([0-9\.\-]+)/);
      if (llMatch) {
        lat = parseFloat(llMatch[1]);
        lng = parseFloat(llMatch[2]);
      }

      events.push({
        id: sr,
        monthKey: mKey,
        month: mLabel,
        zone: z,
        zoneName: zName,
        prabhag: (r[4] || '').trim(),
        area: (r[5] || '').trim(),
        disease: (r[6] || '').trim() || "Water-borne Event",
        lat: lat,
        lng: lng,
        latlong: latlong,
        type: "Water-borne Event"
      });
    }

    // 4. Process Outbreaks
    const outbreakRows = parseCSV(outbreakCsv);
    let obHeaderIdx = 0;
    for (let i = 0; i < outbreakRows.length; i++) {
      if (outbreakRows[i][0] && outbreakRows[i][0].trim() === 'Sr No') {
        obHeaderIdx = i;
        break;
      }
    }
    const outbreaks = [];
    for (let i = obHeaderIdx + 1; i < outbreakRows.length; i++) {
      const r = outbreakRows[i];
      const sr = (r[0] || '').trim();
      if (!sr) continue;

      const rawM = (r[1] || '').trim();
      const mKey = formatMonthKey(null, rawM);
      const mLabel = formatMonthLabel(mKey);
      const z = standardizeZone(r[3]);
      const zName = (r[2] || '').trim() || ZONE_NAMES[z] || z;
      const latlong = (r[6] || '').trim();
      const mapUrl = (r[7] || '').trim();

      let lat = null, lng = null;
      const llMatch = latlong.match(/([0-9\.\-]+)\s*,\s*([0-9\.\-]+)/);
      if (llMatch) {
        lat = parseFloat(llMatch[1]);
        lng = parseFloat(llMatch[2]);
      }

      outbreaks.push({
        id: sr,
        monthKey: mKey,
        month: mLabel,
        zone: z,
        zoneName: zName,
        area: (r[4] || '').trim(),
        disease: (r[5] || '').trim() || "Water-borne Outbreak",
        lat: lat,
        lng: lng,
        latlong: latlong,
        mapUrl: mapUrl,
        type: "Water-borne Outbreak"
      });
    }

    // 5. Process Water Samples (Extract from individual monthly tables for 100% accuracy)
    const waterRows = parseCSV(waterCsv);
    const waterMonthlyMap = {};
    const wsZonewise = [];
    let currMonthKey = "";

    for (let i = 0; i < waterRows.length; i++) {
      const r = waterRows[i];
      if (!r || r.length === 0) continue;
      const col0 = (r[0] || '').trim();

      const mMatch = col0.match(/^(Aug|Sep|Oct|Nov|Dec|Jan|Feb|Mar|Apr|May|Jun|Jul)-[0-9]{2}/i);
      if (mMatch) {
        currMonthKey = formatMonthKey(null, col0);
        continue;
      }

      if (col0.toLowerCase() === 'total' && currMonthKey) {
        const sent = parseInt((r[2] || '').trim(), 10) || 0;
        const pot = parseInt((r[3] || '').trim(), 10) || 0;
        const notPot = parseInt((r[4] || '').trim(), 10) || 0;
        const rate = sent > 0 ? parseFloat(((notPot / sent) * 100).toFixed(1)) : 0.0;

        waterMonthlyMap[currMonthKey] = {
          monthKey: currMonthKey,
          month: formatMonthLabel(currMonthKey),
          sent: sent,
          potable: pot,
          notPotable: notPot,
          contaminationRate: rate
        };
        continue;
      }

      if (/^Zone\s*(\d+)/i.test(col0) && currMonthKey) {
        const z = standardizeZone(col0);
        const zn = (r[1] || '').trim() || ZONE_NAMES[z] || z;
        const sentVal = parseInt((r[2] || '').trim(), 10) || 0;
        const potVal = parseInt((r[3] || '').trim(), 10) || 0;
        const notPotVal = parseInt((r[4] || '').trim(), 10) || 0;
        const rate = sentVal > 0 ? parseFloat(((notPotVal / sentVal) * 100).toFixed(1)) : 0.0;

        wsZonewise.push({
          monthKey: currMonthKey,
          month: formatMonthLabel(currMonthKey),
          zone: z,
          zoneName: zn,
          sent: sentVal,
          potable: potVal,
          notPotable: notPotVal,
          contaminationRate: rate
        });
      }
    }

    const monthChronology = ["2025-08","2025-09","2025-10","2025-11","2025-12","2026-01","2026-02","2026-03","2026-04","2026-05","2026-06","2026-07","2026-08"];
    const waterMonthly = monthChronology
      .filter(k => waterMonthlyMap[k])
      .map(k => waterMonthlyMap[k]);

    return {
      metadata: {
        title: "NMC Water-Borne Disease & ADD Surveillance Intelligence Data",
        generatedAt: new Date().toISOString(),
        source: "Google Sheets (Live Live-Sync)",
        sheetUrl: "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub",
        totalLinelist: linelist.length,
        totalHighRiskAreas: hra.length,
        totalEvents: events.length,
        totalOutbreaks: outbreaks.length,
        totalWaterSamples: waterMonthly.reduce((acc, w) => acc + w.sent, 0),
        totalNotPotableWater: waterMonthly.reduce((acc, w) => acc + w.notPotable, 0)
      },
      linelist: linelist,
      highRiskAreas: hra,
      events: events,
      outbreaks: outbreaks,
      waterSampleMonthly: waterMonthly,
      waterSampleZonewise: wsZonewise
    };
  }

  // Quick fingerprint generator to detect whether sheet data actually changed
  function computeFingerprint(data) {
    const lLen = data.linelist ? data.linelist.length : 0;
    const lastCase = lLen > 0 ? (data.linelist[lLen - 1].name + '_' + data.linelist[lLen - 1].monthKey) : '';
    const hLen = data.highRiskAreas ? data.highRiskAreas.length : 0;
    const eLen = data.events ? data.events.length : 0;
    const oLen = data.outbreaks ? data.outbreaks.length : 0;
    const wLen = data.waterSampleMonthly ? data.waterSampleMonthly.length : 0;
    return `${lLen}:${lastCase}:${hLen}:${eLen}:${oLen}:${wLen}`;
  }

  return {
    fetchLiveGoogleSheetData,
    computeFingerprint
  };
})();
