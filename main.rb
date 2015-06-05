require 'curses'
require './map'

class Main

  def initialize
    @WINDOW_HEIGHT = 24
    @WINDOW_WIDTH = 80

    @map = Map.new({:width => @WINDOW_WIDTH, :height => @WINDOW_HEIGHT})
    @map.cellular_automata(3, 6, 2);

    @player = @map.pick_random_empty_point();

    Curses.init_screen()
    Curses.noecho()
    Curses.curs_set(0)
    @win = Curses::Window.new(24, 80, 0, 0)
    main()
    @win.close
  end

  def main

    title = "YGGDRASIL"
    @win.setpos(@WINDOW_HEIGHT/2-1, @WINDOW_WIDTH/2-1 - title.length/2)
    @win.addstr(title)

    # c = @win.getch()
    @win.clear();

    esc = false
    while(!esc)
      @win.clear();

      (@map.height).times do |y|
        (@map.width).times do |x|
          if(@map.is_solid?(x, y))
            @win.addstr("#")
          else
            @win.addstr(".")
          end
        end
      end

      @win.setpos(@player[:y], @player[:x])
      @win.addstr("@")

      c = @win.getch()

      if(c == 'h' && !@map.is_solid?(@player[:x] - 1, @player[:y]))
        @player[:x] -= 1
      elsif(c == 'j' && !@map.is_solid?(@player[:x], @player[:y] + 1))
        @player[:y] += 1
      elsif(c == 'k' && !@map.is_solid?(@player[:x], @player[:y] - 1))
        @player[:y] -= 1
      elsif(c == 'l' && !@map.is_solid?(@player[:x] + 1, @player[:y]))
        @player[:x] += 1
      elsif(c == 'b' && !@map.is_solid?(@player[:x] - 1, @player[:y] + 1))
        @player[:x] -= 1
        @player[:y] += 1
      elsif(c == 'y' && !@map.is_solid?(@player[:x] - 1, @player[:y] - 1))
        @player[:x] -= 1
        @player[:y] -= 1
      elsif(c == 'u' && !@map.is_solid?(@player[:x] + 1, @player[:y] - 1))
        @player[:x] += 1
        @player[:y] -= 1
      elsif(c == 'n' && !@map.is_solid?(@player[:x] + 1, @player[:y] + 1))
        @player[:x] += 1
        @player[:y] += 1
      elsif(c == 'q')
        esc = true
      end

      @win.refresh()

    end

  end

end

main = Main.new()
