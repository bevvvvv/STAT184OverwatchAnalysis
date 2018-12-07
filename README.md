# STAT184OverwatchAnalysis
Overwatch player analysis for PSU Stat 184 final project. The goal of this project is to be able to determine player rankings from player data.

# Usage
Run Rscript overwatchAnalysis.r to run the analysis. 
Only the analysis runs by default
Current run options:
1. --install
    * If equal to true will install all required packages from default CRAN mirror
2. --tags
    * If equal to true will scrape battle tags from first 950 pages of OW PC leaderboards
3. --pro
    * If euqal to true will scrape profile data from battle tags. This is an extremely slow process and scrapes approximately 9500 records be default.
4. --a
    * Default value is true and performs the data analysis including training model and creating graphs.
    * In the future will have separate options for different analysis functions.
        
# Findings
The machine learning model can currently only predict within 400 SR on average. I believe that if I scrape a lot more records this will improve, since I saw an improvement using 8,000 training rows versus 6,500 rows.
