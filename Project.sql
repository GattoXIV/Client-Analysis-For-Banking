/*
 * --------------------------------------------------------------------------
 * PROGETTO: Banking Intelligence - Customer Analytical Record (CAR)
 * --------------------------------------------------------------------------
 * OBIETTIVO: 
 * Creazione di una tabella denormalizzata (una riga per cliente) da utilizzare
 * come input per modelli di Machine Learning Supervisionato (es. Churn, Cross-sell).
 *
 * DESCRIZIONE LOGICA:
 * 1. Granularità: Aggregazione dai livelli transazionali (molti-a-uno) al livello cliente (uno-a-uno).
 * 2. Feature Engineering:
 * - Demografiche: Calcolo dell'età anagrafica attuale.
 * - Asset Allocation: Pivot dei tipi di conto per analizzare la diversificazione del portafoglio.
 * - Comportamentali: Calcolo di Recency, Frequency e Monetary (RFM) per entrate/uscite.
 * 3. Data Cleaning: 
 * - Gestione dei valori NULL tramite COALESCE/CASE per garantire input numerici validi (0) ai modelli.
 */

SELECT 
    -- ID univoco per il join con altre tabelle o per l'indicizzazione nel DataFrame pandas
    cli.id_cliente,
    
    -- ========================================================================
    -- 1. FEATURE DEMOGRAFICHE
    -- ========================================================================
    -- Calcoliamo l'età dinamica. Fondamentale per segmentare il ciclo di vita del cliente.
    -- (Nota: TIMESTAMPDIFF è specifico per MySQL/MariaDB. Su altri DB usare DATEDIFF/AGE)
    TIMESTAMPDIFF(YEAR, cli.data_nascita, CURDATE()) AS eta,
    
    -- ========================================================================
    -- 2. FEATURE DI POSSESSO PRODOTTI (Engagement)
    -- ========================================================================
    -- Numero totale di conti attivi: proxy della fedeltà (Stickiness).
    COUNT(DISTINCT c.id_conto) AS numero_totale_conti,
    
    -- ONE-HOT ENCODING DEI TIPI DI CONTO
    -- Trasformiamo la variabile categorica 'tipo_conto' in feature numeriche distinte.
    -- Questo permette al modello di pesare diversamente il possesso di un conto 'Business' vs 'Famiglie'.
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Base' THEN 1 ELSE 0 END) AS num_conti_base,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Business' THEN 1 ELSE 0 END) AS num_conti_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' THEN 1 ELSE 0 END) AS num_conti_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 ELSE 0 END) AS num_conti_famiglie,

    -- ========================================================================
    -- 3. FEATURE COMPORTAMENTALI GLOBALI (Volume & Valore)
    -- ========================================================================
    -- Analisi macroscopica dei flussi finanziari.
    -- L'uso di CASE...ELSE 0 serve a imputare "Zero" ai clienti inattivi, evitando i NaN.
    
    -- FREQUENCY: Numero di operazioni (Attività del cliente)
    COUNT(CASE WHEN tt.segno = '-' THEN 1 END) AS num_transazioni_uscita_tot,
    COUNT(CASE WHEN tt.segno = '+' THEN 1 END) AS num_transazioni_entrata_tot,
    
    -- MONETARY: Volumi transati (Valore del cliente)
    -- Arrotondamento a 2 decimali per pulizia del dato in input.
    ROUND(SUM(CASE WHEN tt.segno = '-' THEN t.importo ELSE 0 END), 2) AS importo_totale_uscita,
    ROUND(SUM(CASE WHEN tt.segno = '+' THEN t.importo ELSE 0 END), 2) AS importo_totale_entrata,

    -- ========================================================================
    -- 4. FEATURE COMPORTAMENTALI DI DETTAGLIO (Deep Dive)
    -- ========================================================================
    -- Feature incrociate (Interaction Features) per capire l'utilizzo specifico dei prodotti.
    
    -- --- CONTO BASE (Analisi Operatività Quotidiana) ---
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Base' THEN 1 END) AS num_uscita_base,
    ROUND(SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Base' THEN t.importo ELSE 0 END), 2) AS imp_uscita_base,
    
    -- --- CONTO BUSINESS (Analisi Operatività Aziendale) ---
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Business' THEN 1 END) AS num_uscita_business,
    ROUND(SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Business' THEN t.importo ELSE 0 END), 2) AS imp_uscita_business,

    -- --- CONTO PRIVATI (Analisi Spese Personali) ---
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Privati' THEN 1 END) AS num_uscita_privati,
    ROUND(SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Privati' THEN t.importo ELSE 0 END), 2) AS imp_uscita_privati,

    -- --- CONTO FAMIGLIE (Analisi Gestione Domestica) ---
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 END) AS num_uscita_famiglie,
    ROUND(SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN t.importo ELSE 0 END), 2) AS imp_uscita_famiglie

FROM Cliente cli
-- ========================================================================
-- STRATEGIA DI JOIN
-- ========================================================================
-- Utilizziamo LEFT JOIN per preservare l'intero universo clienti (Population).
-- Escludere i clienti senza conti/transazioni (INNER JOIN) introdurrebbe un 
-- "Survival Bias", impedendo al modello di imparare dai clienti inattivi (potenziali Churn).
LEFT JOIN Conto c ON cli.id_cliente = c.id_cliente
LEFT JOIN Tipo_conto tc ON c.id_tipo_conto = tc.id_tipo_conto
LEFT JOIN Transazioni t ON c.id_conto = t.id_conto
LEFT JOIN Tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione

-- Raggruppamento finale per ottenere la chiave univoca 'id_cliente'
GROUP BY cli.id_cliente, cli.data_nascita;