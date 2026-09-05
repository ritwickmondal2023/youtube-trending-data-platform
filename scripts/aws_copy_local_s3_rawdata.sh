$regions = @("CA","DE","FR","GB","IN","JP","KR","MX","RU","US")

foreach ($region in $regions)
{
    aws s3 cp "$($region)videos.csv" `
        "s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=$($region.ToLower())/"

    aws s3 cp "$($region)_category_id.json" `
        "s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=$($region.ToLower())/"
}



# For individual manual upload, below is the manual code

# CSV Files:

# aws s3 cp CAvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=ca/
# aws s3 cp DEvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=de/
# aws s3 cp FRvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=fr/
# aws s3 cp GBvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=gb/
# aws s3 cp INvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=in/
# aws s3 cp JPvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=jp/
# aws s3 cp KRvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=kr/
# aws s3 cp MXvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=mx/
# aws s3 cp RUvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=ru/
# aws s3 cp USvideos.csv s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics/region=us/

# JSON Files:

# aws s3 cp CA_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=ca/
# aws s3 cp DE_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=de/
# aws s3 cp FR_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=fr/
# aws s3 cp GB_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=gb/
# aws s3 cp IN_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=in/
# aws s3 cp JP_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=jp/
# aws s3 cp KR_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=kr/
# aws s3 cp MX_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=mx/
# aws s3 cp RU_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=ru/
# aws s3 cp US_category_id.json s3://yt-dataprocessing-s3-bronze-ritwick-portfolio/youtube/raw_statistics_reference_data/region=us/