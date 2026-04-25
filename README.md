# Noise Solution Impact Dashboard

> *Digital music mentoring for youth at risk — impact through Self-Determination Theory*

**Status:** 🚧 In development  
**Built with:** R Shiny + shiny.semantic  
**Live app:** TBC

---

## Overview

An interactive dashboard analysing the impact of Noise Solution's digital music mentoring programme using Self-Determination Theory (SDT). Built for the Data ChangeMakers volunteer initiative.

### Three Basic Psychological Needs (BPNs)

| Need | Definition |
|------|------------|
| **Competence** | Feeling good at something |
| **Autonomy** | A sense of feeling in control |
| **Relatedness** | Feeling connected to and valued by others |

Scores are derived from AI analysis (Transceve) of session reflection videos, averaged across up to 5 analysis runs per session.

---

## Dashboard Structure

| Tab | Purpose |
|-----|---------|
| **Impact** | 10-second headline view — KPIs, hero quote, takeaway |
| **How Support Varies** | BPN score distributions and sector breakdowns |
| **In Their Words** | Participant voice — positive moments and challenges |
| **Over Time** | Session trajectory for multi-session participants |

---

## Data

- **229 sessions** across **35 participants**
- Three BPN scores per session (1–9 scale)
- Qualitative highlights per domain (most positive/negative sentences)
- Demographic data: age, gender, sector

*All data provided by Noise Solution. Participants have consented to analysis.*

---

## Technical Stack

- `shiny` + `shiny.semantic` (Appsilon)
- `ggplot2` + `ggiraph` for interactive charts
- `reactable` for tables
- Deployed on shinyapps.io

---

## Project Notes

Built as part of the [Data ChangeMakers](https://datachangemakers.org) volunteer programme.  
Submission deadline: May 22, 2026.

---

*Steven Ponce — 2026*
