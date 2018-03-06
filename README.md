<!-- README.md is generated from README.Rmd. Please edit that file -->
Predicting March Madness
------------------------

Kaggle's March Madness competition is an accessible introduction to machine learning. If you happen to like college basketball, you'll like that in this competition you can't bust your bracket, since you make a prediction for every game. Plus this year there's a big prize pool, and luck plays a big enough role that you can be a legit contender fairly easily.

In 2016, my simple process using tidyverse functions in R placed in the top 10%. I refined it a bit for 2017 and finished in the top 25%.

I'm sharing my code and process here for others to use as a starting point. My approach is similar to that of the 2014 winners, Gregory Matthews and Michael Lopez. They published [a paper about the role that luck plays in this competition](https://arxiv.org/abs/1412.0248), putting their model in perspective. A takeaway: take my model, tweak it a bit to generate some distance from the field, and you are competitive to win!

What's here
-----------

In the Kaggle competition, you estimate how likely it is that Team A beats Team B, for each of the &gt;1,000 possible matchups in the tournament. **[My guide](march_madness_how_to.md)** documents a set of scripts for each step of:

-   Deciding on possible input parameters
-   Scraping the input data with the `rvest` package
-   Cleaning and joining data sources to get tidy, prediction-ready data
-   Training and evaluating machine learning models on the data
-   Making and submitting predictions

Contact me
----------

Let me know what you think, either on twitter @samfirke or compose a friendly e-mail to: <img src = "http://samfirke.com/wp-content/uploads/2016/07/email_address_whitespace_top.png" alt = "samuel.firke AT gmail" width = "210"/>
