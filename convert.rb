#!/usr/bin/env ruby

require 'csv'
require 'yaml'

VERSION = '1.2.0'

# Which file are we converting?
file = ARGV[0] || exit

# Load the yaml file.
yaml = YAML.load_file(file)

def dismissals_for(delivery)
  delivery['wicket'].is_a?(Array) ? delivery['wicket'] : [delivery['wicket']]
end

def dismissal_methods_for(delivery)
  return '' unless delivery.key?('wicket')
  dismissals_for(delivery).map { |dismissal| dismissal['kind'] }.join(', ')
end

def dismissed_players_for(delivery)
  return '' unless delivery.key?('wicket')
  dismissals_for(delivery).map { |dismissal| dismissal['player_out'] }.join(', ')
end

# Generate the csv.
csv_string = CSV.generate do |csv|
  csv << ['version', VERSION]

  # Add the info section.
  yaml['info']['teams'].each do |team|
    csv << ['info', 'team', team]
  end
  csv << ['info', 'gender', yaml['info']['gender']]

  yaml['info']['dates'].each do |date|
    csv << ['info', 'date', date.strftime("%Y/%m/%d")]
  end

  if yaml['info'].key?('competition') && yaml['info']['competition'] == 'IPL'
    csv << ['info', 'competition', 'Indian Premier League']
  end

  csv << ['info', 'venue', yaml['info']['venue']]
  csv << ['info', 'city', yaml['info']['city']]
  if yaml['info'].has_key?('neutral_venue')
    csv << ['info', 'neutralvenue', 'true']
  end

  csv << ['info', 'toss_winner', yaml['info']['toss']['winner']]
  csv << ['info', 'toss_decision', yaml['info']['toss']['decision']]

  if yaml['info'].key?('player_of_match')
    yaml['info']['player_of_match'].each do |pom|
      csv << ['info', 'player_of_match', pom]
    end
  end

  # Officials
  if yaml['info'].key?('umpires')
    yaml['info']['umpires'].each do |name|
      csv << ['info', 'umpire', name]
    end
  end

  # Outcome
  if yaml['info']['outcome'].key?('result')
    csv << ['info', 'outcome', yaml['info']['outcome']['result']]

    if yaml['info']['outcome'].key?('eliminator')
      csv << ['info', 'eliminator', yaml['info']['outcome']['eliminator']]
    elsif yaml['info']['outcome'].key?('bowl_out')
      csv << ['info', 'bowl_out', yaml['info']['outcome']['bowl_out']]
    elsif yaml['info']['outcome'].key?('method')
      csv << ['info', 'method', yaml['info']['outcome']['method']]
    end
  end

  if yaml['info']['outcome'].key?('winner')
    csv << ['info', 'winner', yaml['info']['outcome']['winner']]

    yaml['info']['outcome']['by'].each_pair do |k,v|
      csv << ['info', "winner_#{k}", v]
    end
    if yaml['info']['outcome'].key?('method')
      csv << ['info', 'method', yaml['info']['outcome']['method']]
    end
  end

  # Now deal with the innings.
  yaml['innings'].each_with_index do |inning, inning_no|
    inning.each_pair do |inning_name, inning_data|
      if inning_data.key?('penalty_runs')
        %w(pre post).each do |type|
          next unless inning_data['penalty_runs'].key?(type)
          csv << [
            'penalty_runs',
            inning_no + 1, type,
            inning_data['penalty_runs'][type]
          ]
        end
      end

      inning_data['deliveries'].each do |delivery_data|
        delivery_data.each_pair do |ball_no, delivery|
          csv << [
            'ball',
            inning_no + 1,
            ball_no,
            inning_data['team'],
            delivery['batsman'],
            delivery['non_striker'],
            delivery['bowler'],
            delivery['runs']['batsman'],
            delivery['runs']['extras'],
            dismissal_methods_for(delivery),
            dismissed_players_for(delivery)
          ]
        end
      end
    end
  end
end

puts csv_string
