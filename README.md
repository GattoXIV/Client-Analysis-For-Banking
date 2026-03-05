# 🏦 Banking Intelligence - Customer Analytical Record (CAR)

## 📝 Descrizione del Progetto
Questo script SQL è progettato per la creazione di un Customer Analytical Record (CAR), una tabella denormalizzata (una riga per cliente) essenziale come input per modelli di Machine Learning Supervisionato (es. previsione del Churn o Cross-Selling).

## 🎯 Obiettivi Principali
* **Aggregazione Dati:** Passaggio da una granularità transazionale (molti-a-uno) a una vista a livello cliente (uno-a-uno).
* **Feature Engineering:**
  * Calcolo dell'età dinamica del cliente.
  * Asset Allocation: Pivot dei tipi di conto per valutare la diversificazione del portafoglio.
  * Analisi Comportamentale (RFM): Calcolo di Recency, Frequency e Monetary per entrate e uscite.
* **Gestione Dati Mancanti:** Trattamento dei valori NULL per garantire un input pulito ai modelli predittivi.

## 🛠️ Tecnologie
* SQL (MySQL/MariaDB)
