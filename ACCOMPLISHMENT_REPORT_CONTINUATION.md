# MaDoBaBu's BAT 402 Accomplishment Report — Continuation Draft

*(I-paste ito sa Google Doc niyo simula sa blangkong "Phase 2: Data Preparation"
heading. Ang mga numero ay galing sa aktwal na R script run — reproducible.)*

---

Phase 2: Data Preparation
We ran the full quality audit required by the handout: dim(), head(), str(), summary(), colSums(is.na(df)), and sum(duplicated(df)). The raw file loaded at 1,034 rows and 9 columns, with no formally blank cells — but the audit surfaced hidden problems. The release year was stored as text, with 209 rows recorded as "N/A", and another 209 rows had a completely blank publisher. Three game titles (War Thunder, Apotheon, and Biomutant) appeared twice with conflicting details, all six of those rows carrying zero sales. In two rows the Global column disagreed with the sum of the four regional columns (One Piece: Pirate Warriors 3 and Sniper: Ghost Warrior 3), which pointed to data-entry errors rather than genuine values. Finally, 322 rows showed zero sales in every region — mostly unreleased or untracked titles, meaning no recorded outcome.

Every finding was investigated before any action. We removed the 3 conflicting duplicate titles (keeping the first row of each), re-derived Global as the sum of the four regions for the 2 inconsistent rows, and removed the 321 remaining rows with no recorded sales in any region, since a missing outcome cannot train or test a model. The 209 blank publishers were filled with the most common publisher (Namco Bandai Games) and the 3 remaining unknown years with the median year (2016). This left a clean working dataset of 710 rows — comfortably above the 200-row minimum.

We then engineered three new variables, each with a business justification: (1) PublisherTier — "Major" if a publisher has 25 or more PS4 titles (8 publishers qualify), because publisher scale proxies marketing muscle and retail access; (2) LifecyclePhase — Launch (2013–2014), Peak (2015–2016), and Late (2017–2020), because the same game sells differently depending on how many consoles are in homes when it launches; and (3) GenreGroup — genres with fewer than 20 games were merged into "Other" because rare categories are too thin to estimate reliably. The prepared dataset was exported with write.csv() and submitted alongside the script.

Phase 3: Predictive Model
We split the data 80/20 using set.seed(42), giving 568 training rows and 142 test rows, and built the model on the training set only. Our model is a multiple linear regression: Global ~ NorthAmerica + LifecyclePhase + GenreGroup + PublisherTier. Europe, Japan, and Rest-of-World sales were deliberately excluded as predictors because they become known at the same time as the global figure and would make the model circular — North America is used because it is genuinely available weeks earlier.

On the 142 unseen test games, the model produced an RMSE of 1.133 million units and an R-squared of 0.800. The headline RMSE is inflated by a few blockbusters in the test set: for the 116 test games that sold under one million units, the RMSE is only 0.164 million units. Interpreted in business terms, each additional 1 million North American units is associated with roughly 2.48 million more global units — games that win in North America win over twice as big worldwide. A model chart (actual versus predicted sales on the test set) was produced and included in the report.

Phase 4: Model Evaluation
Overfitting diagnosis. The training RMSE is 0.480 million units against a test RMSE of 1.133 million. Before declaring overfitting, we ran the required five-fold cross-validation on the training set: fold results were 0.418, 0.501, 0.542, 0.373, and 0.630, averaging 0.493. Because the cross-validation average reproduces the training error almost exactly, we concluded that the gap is caused by a handful of blockbusters landing in the test set, not by the model memorising noise. Diagnosis: good fit, no material overfitting.

What-if scenario. We asked a concrete business question: our studio's new Action game just posted 300,000 North American units — what global total should we plan around? Feeding hypothetical inputs into the model, the forecast came out at roughly 810,000 worldwide units for a major publisher (745,000 for a small publisher), rising to about 2.55 million if the game opens with a full 1 million North American units. This informs the manufacturing commitment decision made two to three weeks after launch.

Monte Carlo risk simulation. Since the early North American figure itself is uncertain, we simulated 5,000 launches with set.seed(42), drawing the NA result from rnorm() and the genre from the realistic genre mix. The mean simulated forecast was 0.805 million units, the 5th–95th percentile range was roughly 0 to 1.708 million, and the probability of finishing below 0.30 million units was 18.9%. The histogram of simulated outcomes is included in the report. The decision this supports: commit manufacturing to the middle of the range and keep a contingency trigger for the 1-in-5 downside case.

Phase 5: Ethics and Privacy
We identified a sampling bias specific to our model and data: VGChartz under-tracks small, digital-only, and Japan-market titles, so the 321 zero-sales rows we removed may contain games that really sold but were never counted. Because of this, forecasts for niche titles lean systematically low, and the developers and staff behind those games could see projects unfairly deprioritised if managers treat forecasts as verdicts. We assessed the project against two principles of RA 10173 (Data Privacy Act of 2012): transparency — the data source, scraping origin, and modelling method are fully disclosed in the report; and proportionality — the dataset contains no personal information, only game titles and aggregate sales, so only the minimum fields needed for the forecast are used and no data-subject rights are engaged. As a concrete mitigation, every forecast is released with its uncertainty range attached, and forecasts for publishers absent from the training data are labelled low-confidence, so no single mistaken forecast can automatically cancel a project.

Phase 6: Communication
The written report was assembled following the required five-section structure (Executive Summary, Problem and Data, Models and Results, What It Means, Limitations and Recommendations) within six pages excluding appendices, with the raw R output and full code placed in the appendix. The Executive Summary was written in plain language with no statistical terms, and the "What It Means" section translates every metric into business units. The presentation deck contains 12 slides, opens with the SCQA structure (Situation, Complication, Question, Answer), and states the key finding within the first 90 seconds. Two or more charts carry message titles and labelled axes with units. The slides were divided among the members so each speaks for a comparable stretch, and the group rehearsed to stay inside the 7-to-10-minute window with time to spare for questions.

Phase 7: Optimization (optional)
Our business problem does contain a resource-allocation decision (how many units to manufacture per title), so a linear programming formulation is possible. However, per the handout's advice to ask before committing time, the group will first confirm with the instructor whether to pursue this component. Status: on hold pending instructor's go-signal.

---

*Updated Task Manager rows (i-update rin ang table sa taas):*

| TASKS | STATUS | TIMEFRAME |
|---|---|---|
| Phase 5: Ethics and Privacy | Completed | Nov 26, 2026 |
| Phase 6: Communication | Completed | Nov 28 – Dec 2, 2026 |
| Phase 7: Optimization (optional) | On hold – to confirm with instructor | — |
