# MaDoBaBu's BAT 402 Accomplishment Report — Continuation Draft (matched tone)

*(I-paste ito sa Google Doc simula sa blangkong "Phase 2: Data Preparation" heading.)*

---

Phase 2: Data Preparation


I. Quality Audit
Following the standard prescribed in the handout, we ran the full set of quality checks on the raw file: dim(), head(), str(), summary(), colSums(is.na(df)), and sum(duplicated(df)). The dataset loaded at 1,034 rows and 9 columns, and on the surface appeared complete, with no formally blank cells. However, a closer look revealed that this cleanliness was only superficial. The release year column was stored as text rather than as numbers, with 209 of the entries recorded simply as "N/A", and another 209 rows carried a completely blank publisher. Three game titles — War Thunder, Apotheon, and Biomutant — appeared twice under conflicting details, and all six of those rows carried zero sales, suggesting they were draft entries of the same records. Further checks exposed two rows where the Global column did not agree with the sum of the four regional columns, pointing to data-entry errors rather than genuine sales figures, and 322 rows that showed zero sales across every region, belonging mostly to titles that had not yet been released or that the tracker never recorded.


II. Cleaning and Investigation
Rather than deleting rows outright, we investigated each problem before acting on it, as the handout requires. The three conflicting duplicate titles were resolved by keeping the first recorded instance of each. The two mismatched Global figures were re-derived from their regional components, which we treated as the more reliable values. For the 322 zero-sales rows, we recognised that a game with no recorded outcome cannot train or test a model, and so these rows were removed; the 209 blank publishers were filled with the most common publisher in the dataset, and the three remaining unknown years with the median year, both accepted treatments that preserve otherwise usable records. From a business perspective, we took care to document that these zero-sales titles are missing data rather than true commercial flops, since treating them as real zeros would have distorted the demand picture the model is meant to capture. The cleaned working dataset settled at 710 rows, comfortably above the 200-row minimum set for the project.


III. Feature Engineering
Three new variables were created from existing columns, each carrying a business justification. PublisherTier classifies a publisher as Major if it has released twenty-five or more PS4 titles, of which eight publishers qualify, on the reasoning that publisher scale proxies marketing muscle and retail access. LifecyclePhase groups the release year into Launch (2013–2014), Peak (2015–2016), and Late (2017–2020) windows, because the same game sells differently depending on how many consoles are in homes at the moment it reaches shelves. GenreGroup merges genres with fewer than twenty games into a single Other category, since rare genres are too thin to support reliable estimates. The prepared dataset was then exported with write.csv() and submitted alongside the script.


Phase 3: Predictive Model


I. Model Building
We split the clean dataset 80/20 using set.seed(42), producing 568 training rows and 142 test rows, and built the model on the training set only. Given that our outcome is a number — total global unit sales — we chose a multiple linear regression of the form Global ~ NorthAmerica + LifecyclePhase + GenreGroup + PublisherTier. One deliberate decision shaped the model's design: Europe, Japan, and Rest-of-World sales were excluded as predictors because they become known at the same moment as the global figure itself, and including them would have made the model circular. North America alone was retained as the sales signal, since it is genuinely available weeks before the worldwide picture settles.


II. Results and Interpretation
On the 142 unseen test games, the model produced an RMSE of 1.133 million units against a mean test sale of 1.006 million, with an R-squared of 0.800. The headline error is concentrated in a handful of blockbusters that landed in the test set; for the 116 test games that sold under one million units — the ordinary game, about nine in ten titles — the typical miss shrinks to just 0.164 million copies. Translated into business terms, each additional one million North American units is associated with roughly 2.48 million more global units: games that win in North America win over twice as big worldwide. An actual-versus-predicted chart on the test set was produced and included in the report as the required model chart.


Phase 4: Model Evaluation


I. Overfitting Diagnosis and Cross-Validation
Because honest evaluation matters more to us than a flattering number, the model was examined on four counts. First, performance was computed on the training set as well, yielding an RMSE of 0.480 million units against the test figure of 1.133 million — a gap that looks alarming at first glance. Second, the required five-fold cross-validation was run on the training data, producing fold results of 0.418, 0.501, 0.542, 0.373, and 0.630, averaging 0.493. Since the cross-validation average reproduces the training error almost exactly, we concluded that the gap does not come from the model memorising noise but from a few blockbusters landing in the test set. The diagnosis: a good fit with no material overfitting.


II. What-If Scenario
Third, we posed a concrete business question: suppose our studio's new Action game has just posted 300,000 North American units — what global total should the manufacturing plan be built around? Feeding hypothetical inputs into the fitted model, the forecast came out at roughly 810,000 worldwide units for a major publisher and 745,000 for a small one, rising to about 2.55 million if the game were to open with a full one million North American units. This is the number that informs the production commitment made two to three weeks after launch.


III. Monte Carlo Risk Simulation
Fourth, recognising that the early North American figure is itself uncertain, we ran a Monte Carlo simulation of 5,000 launches using set.seed(42), drawing the NA result with rnorm() and the genre from the realistic genre mix. The mean simulated forecast settled at 0.805 million units, the 5th–95th percentile spanned roughly zero to 1.708 million, and the chance of finishing below 0.30 million units came out at 18.9%. The histogram of simulated outcomes is included in the report. The decision this supports is straightforward: commit manufacturing to the middle of the range and keep a contingency trigger ready for the one-in-five downside case.


Phase 5: Ethics and Privacy
Turning the lens on our own model, we identified a sampling bias rooted in the data source itself: VGChartz under-tracks small, digital-only, and Japan-market titles, which means the 321 zero-sales rows we removed during cleaning may include games that genuinely sold but were simply never counted. The practical consequence is that forecasts for niche titles lean systematically low, and the developers and staff behind those games could see their projects unfairly deprioritised if managers come to treat forecasts as verdicts rather than estimates. Assessing the project against the principles of RA 10173, the Data Privacy Act of 2012, we found the principles of transparency and proportionality both satisfied: the data source, scraping origin, and modelling method are fully disclosed in the report, and the dataset contains no personal information at all — only game titles and aggregate sales — so only the minimum fields needed for the forecast are used and no data-subject rights are engaged. As a concrete mitigation, every forecast is released with its uncertainty range attached, and forecasts for publishers absent from the training data are labelled low-confidence, ensuring that no single mistaken forecast can automatically cancel a project.


Phase 6: Communication
The written report was assembled following the required five-section structure — Executive Summary, Problem and Data, Models and Results, What It Means, and Limitations and Recommendations — within the six-page limit excluding appendices, with the full R code and raw output carried in the appendix rather than the body. The Executive Summary was written in plain language with no statistical terms at all, and the What It Means section translates every metric into business units, keeping the report readable by both a technical reviewer and a business decision-maker. The presentation deck runs twelve slides, opens with the SCQA structure, and states the key finding within the first ninety seconds. Two or more charts carry message titles and axes labelled with units. The slides were divided among the members so that each speaks for a comparable stretch, and the group rehearsed to stay comfortably inside the seven-to-ten-minute window, leaving room for the five-minute question period.


Phase 7: Optimization (optional)
Our business problem does contain a resource-allocation decision at its core — how many units of each title to manufacture — so a linear programming formulation is attainable with the lpSolve package. However, in line with the handout's advice to ask before committing time to an optional component, the group has chosen to confirm first with the instructor whether to pursue it before beginning the formulation.
