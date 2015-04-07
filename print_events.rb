#!/usr/bin/env ruby

require 'rubygems'
require 'ri_cal'
require 'open-uri'
require 'tzinfo'
require 'date'

day_start = "Monday"
day_length = 7
tzid = "America/Los_Angeles"
filename = ARGV[0] || "latest.txt"

def date_of_next(day)
  date  = Date.parse(day)
  delta = date >= Date.today ? 0 : 7
  date + delta
end

rstart = date_of_next("Monday")
rend = rstart + day_length

calendars = nil
addr = "https://www.google.com/calendar/ical/pushboardportland%40gmail.com/public/basic.ics" 

open(addr) do |cal|
  calendars = RiCal.parse(cal)
end

dformat = "%A, %B %d"
tformat = "%I:%M%p"

dlast = nil

tz = TZInfo::Timezone.get(tzid)

events = []
calendars.each do |calendar|
  calendar.events.each do |event|
    s = event.dtstart
    e = event.dtend || event.dtstart

    s = DateTime.parse(s.to_s) if s.is_a?(Date)
    e = DateTime.parse(e.to_s) if e.is_a?(Date)

    s = tz.utc_to_local(s)
    e = tz.utc_to_local(e)

    if (s >= rstart and e < rend)
      #update time zone
      event.dtstart = s
      event.dtend = e
      events << event
    end
  end
end

events.sort! { |a, b| a.dtstart <=> b.dtstart }

now = DateTime.now
File.open(filename, "w") do |f|
  f.puts "generated: #{now.strftime(dformat + ' %Y')} #{now.strftime('%I:%M%p')}"

  events.each do |event|
    s = event.dtstart
    e = event.dtend

    d = s.strftime(dformat)
    if d != dlast
      f.puts "\n<strong>\n================"
      f.puts "<br>#{d}"
      f.puts "<br>================\n</strong>\n\n"
      dlast = d
    else
      f.puts "\n"
    end
    f.puts "<p>"
    st = s.strftime(tformat).sub(/\A0/, "")
    f.puts "<span style='color:rgb(255,255,255);background-color:rgb(0,0,0)'>#{st}</span> #{event.summary}"

    f.puts "<br>#{event.location.sub(/, Portland.*/, "")}"
    f.puts "<br>#{event.description}" if event.description.size > 0
    f.puts "</p>"
  end
end
