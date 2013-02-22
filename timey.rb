require 'rubygems'
require 'bundler/setup'
Bundler.require
 
stuff = {}
apps = {}
@wait_duration = 10
@idle_duration = 60*5

def this script_name
  if script_name =~ /ruby #{__FILE__}/
    true
  else
    false
  end
end

def idle_time
  `ioreg -c IOHIDSystem | perl -ane 'if (/Idle/) {$idle=(pop @F)/1000000000; print $idle;last}'`.to_i
end

def formatted seconds
  "#{seconds} / #{(seconds/60).to_f} / #{(seconds/60/60).to_f}"
end

def pretty(things, headings)

  table_rows = []
  things.each_pair do |thing, duration|
    table_rows << [thing, (formatted duration)]
  end

  Terminal::Table.new :headings => headings, :rows => table_rows

end

def pretty_it_all_up(files, apps)

  puts
  puts pretty apps, ['Application', 'Seconds / Minutes / Hours']
  puts
  puts pretty files, ['File', 'Seconds / Minutes / Hours']
  puts

end

def current_thing
  thing = ""
  frontmost = Appscript.app('System Events').application_processes.get.select{ |a| a.frontmost.get }.first

  if frontmost and idle_time < @idle_duration

    thing += frontmost.name.get

    if frontmost.windows.count > 0
      window = frontmost.windows.first
      thing += "|#{window.name.get}"

      if frontmost.name.get == 'Google Chrome'
        tab = Appscript.app('Google Chrome').windows[0].active_tab
        thing += "|#{tab.name.get}"
      end
    end

    return thing, frontmost.name.get

  else 
    puts "Idle time: #{idle_time}"
  end

end

while true

  begin

    file, app = current_thing
    unless this file
      if stuff[file]
        stuff[file] += @wait_duration
      else
        stuff[file] = @wait_duration
      end

      if apps[app]
        apps[app] += @wait_duration
      else
        apps[app] = @wait_duration
      end
    end

    sleep @wait_duration

  rescue SystemExit, Interrupt
      pretty_it_all_up stuff, apps
      exit
  rescue Exception => e
      puts "Exception #{e.to_s}"
      exit
  end

end

# Chrome Active Tab
# http://stackoverflow.com/questions/2483033/get-the-url-of-the-frontmost-tab-from-chrome-on-os-x
# Active Window
# http://stackoverflow.com/questions/480866/get-the-title-of-the-current-active-window-document-in-mac-os-x
# System Idle Time
# http://www.dssw.co.uk/sleepcentre/threads/system_idle_time_how_to_retrieve.html
# ioreg -c IOHIDSystem | perl -ane 'if (/Idle/) {$idle=(pop @F)/1000000000; print $idle,"\n"; last}'