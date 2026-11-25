# MaDoBaBu's BAT 402 Accomplishment Report — Continuation Draft (simpler natural voice)

*(I-paste ito sa Google Doc simula sa blangkong "Phase 2: Data Preparation" heading.)*

---

Phase 2: Data Preparation


We started by running the six quality checks required in the handout: dim(), head(), str(), summary(), colSums(is.na(df)), and sum(duplicated(df)). The raw dataset has 1,034 rows and 9 columns, and at first glance there are no blank cells at all. However, when we inspected the actual values, we discovered several hidden problems. The Year column is stored as text because 209 rows are recorded as "N/A", and 209 rows also have a blank Publisher. We also found three game titles that appear twice with conflicting details (War Thunder, Apotheon, and Biomutant), two rows where the Global figure does not match the sum of the regional sales, and 322 rows with zero sales across all regions.

Before cleaning anything, we investigated each problem first. The duplicate titles were resolved by keeping only the first record of each, since they carried conflicting details and zero sales anyway. For the two rows where Global did not match the regions, we corrected Global by re-adding the four regional values, since these were the ones consistent with the source. The 322 zero-sales rows turned out to be mostly unreleased or untracked titles, so there is no recorded outcome to learn from, and the handout itself states that rows with a missing outcome cannot train or test a model. These were removed too, and we reported the count instead of deleting them quietly. The blank publishers were filled with the most common publisher (Namco Bandai Games) and the remaining unknown years with the median year (2016). After all of this, the clean dataset ends up at 710 rows, still well above the 200-row minimum.

For the engineered features, we created three new variables. PublisherTier marks a publisher as Major when it has at least 25 PS4 titles in the dataset, because publisher size reflects marketing strength and retail reach. LifecyclePhase groups the years into Launch (2013-2014), Peak (2015-2016), and Late (2017-2020), because a game does not sell the same when a console is new compared to when the market is already crowded or slowing down. GenreGroup merges genres with fewer than 20 games into "Other" so the model will not be affected by categories that barely appear. Finally, the prepared dataset was exported using write.csv() to be submitted along with the script. We also want to note that Europe, Japan, and RestofWorld were intentionally set aside as predictor candidates at this stage, for a reason we explain in the next phase.


Phase 3: Predictive Model


We split the clean data 80/20 using set.seed(42), which gave us 568 training rows and 142 test rows, and we built the model on the training set only. Since our outcome is a number, we used a multiple linear regression: Global ~ NorthAmerica + LifecyclePhase + GenreGroup + PublisherTier. One deliberate decision we made here is not to use Europe, Japan, and RestofWorld as predictors. These figures come out at the same time as the global figure itself, so feeding them to the model would be like handing it the answer. North America stays because it is available weeks earlier, which is exactly what our business question needs.

On the test set of 142 games, the model produced an RMSE of 1.133 million units and an R-squared of 0.800. When we examined the errors, we noticed the headline figure is pulled up by a few blockbusters; for the 116 test games under one million units, the RMSE is only 0.164 million, which is a reasonable miss for the typical game. In business terms, one extra million copies in North America goes together with about 2.48 million more copies worldwide, which means games that win in North America also win globally. The required actual-versus-predicted chart on the test set was produced and included in the report.


Phase 4: Model Evaluation


For the overfitting diagnosis, we computed the training performance and compared it with the test performance. The train RMSE is 0.480 while the test RMSE is 1.133, which looked worrying at first. To confirm whether this is really overfitting, we ran the required five-fold cross-validation on the training set. The folds returned 0.418, 0.501, 0.542, 0.373, and 0.630, averaging 0.493. Since the cross-validation average matches the training error almost exactly, we concluded that the gap is caused by the blockbusters that landed in the test set, not by the model memorising the data. So the diagnosis is a good fit with no serious overfitting.

For the what-if scenario, we asked a concrete question: if our studio's new Action game earns 300,000 North American units in its opening, what worldwide total should we plan around? Feeding the hypothetical inputs to the model, the forecast is around 810 thousand units for a major publisher, and around 745 thousand for a small one. If the game instead opened at a full one million NA units, the forecast rises to around 2.55 million. This tells the team what production size is realistic a few weeks after launch, which is the moment the manufacturing decision actually happens.

For the Monte Carlo risk simulation, we recognised that the early NA figure itself is uncertain, so we simulated 5,000 launches using set.seed(42), drawing the NA result with rnorm() and sampling the genre from the realistic mix. The mean forecast is 0.805 million units, the 5th and 95th percentiles span roughly zero to 1.708 million, and the chance of finishing below 0.30 million units is 18.9%. The histogram of the simulation is included in the report. The practical takeaway is to size the production run for the middle of the range and keep a backup plan ready for the roughly one-in-five downside case.


Phase 5: Ethics and Privacy


For the ethics component, we looked at our own model instead of talking in general terms. The bias we identified is a sampling bias that comes from the data source itself: VGChartz records fewer small, digital-only, and Japan-market titles, which means some of the zero-sales rows we removed during cleaning may have been games that actually sold but were never tracked. Because of this, forecasts for niche titles lean low, and the developers behind those games could be affected if managers start treating the forecast as a verdict instead of an estimate.

We then assessed the project against two principles of RA 10173, the Data Privacy Act of 2012. Transparency is satisfied because the source of the data and the entire method are disclosed in our report. Proportionality is satisfied because the dataset contains no personal information, only game titles and aggregate sales, so only the minimum fields needed for the forecast are used and no data-subject rights are involved. For our mitigation, every forecast will be released together with its uncertainty range, and forecasts for publishers not present in the training data will be labelled low-confidence, so that one wrong forecast cannot automatically cancel a project.


Phase 6: Communication


We assembled the written report following the five required sections, staying inside the six-page limit excluding appendices, and all raw R output was placed in the appendix instead of the body. The Executive Summary is written in plain language with no statistical terms, and the What It Means section explains every number in business units for the decision-maker. Our presentation deck has 12 slides, opens with the SCQA structure, and states the key finding within the first 90 seconds. The charts carry message titles and labelled axes with units. We divided the slides among the members so that everyone speaks a comparable stretch, and we rehearsed the delivery to fit inside the 7 to 10 minute limit with room for the question period.


Phase 7: Optimization (optional)


Our business problem does contain a resource allocation decision, since the publisher must decide how many units of each title to manufacture. Because of this, a linear programming component using lpSolve is possible. However, the handout advises asking the instructor before committing time to an optional component, so we plan to confirm first before starting the formulation.
