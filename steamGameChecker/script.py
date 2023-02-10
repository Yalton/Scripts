import sys
from bs4 import BeautifulSoup 
import requests 

import csv



def verify_compat(game):
    print('https://www.protondb.com/search?q=' + game[0])
    html_text = requests.get('https://www.protondb.com/search?q=' + game[0]).text
    print(html_text)
    soup = BeautifulSoup(html_text, 'lxml')
    # jobs = soup.find('span', class_='MedalSummary__ExpandingSpan-sc-1fjwtnh-1 gjnWNf')
    ranking = soup.find('span', class_='gjnWNf').text.replace(' ', '')
    print(game[0] + ',' + ranking)
    
    # for index, job in enumerate(jobs): 
    #     published_date = job.find('span', class_='sim-posted').text.replace(' ', '')
    #     if 'few' in published_date: 
    #         company_name = job.find('h3', class_='joblist-comp-name').text.replace(' ', '')
    #         skill = job.find('span', class_='srp-skills').text.replace(' ', '')
    #         more_info = job.header.h2.a['href']
            # if unfamiliar_skill not in skill:
            #     with open(f'scraped_data/{index}.txt', 'w') as f:
            #         f.write(f"Company Name: {company_name.strip()}")
            #         f.write(f"Required Skills: {skill.strip()}")
            #         f.write(f"More Info: {more_info}")
        
        
if __name__ == '__main__': 
    
    with open("games.csv", newline='') as f:
        reader = csv.reader(f)
        data = list(reader)
    #print(data)
    for game in data:
        verify_compat(game)