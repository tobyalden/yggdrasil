require('matrix')

class Map

  attr_reader(:width, :height, :map)

  def initialize (attributes)
    @width = attributes[:width]
    @height = attributes[:height]
    @map = Array.new(@width)
    @map.each_index() do |index|
      @map[index] = Array.new(@height, false)
    end
  end

  # ---------- CELLULAR AUTOMATA ----------

  #
  def cellular_automata(iterations, min_rooms, num_loops)
    loop do
      randomize_map()
      iterate_automata(iterations)
      break if(count_rooms()[:room_count] >= min_rooms)
    end

    unconnected_rooms = count_rooms()[:rooms]

    while(count_rooms()[:room_count] > 1)
      connect_rooms(count_rooms()[:rooms])
    end
    create_boundaries()

    num_loops.times() do
      connect_rooms(unconnected_rooms)
    end

  end

  def iterate_automata(iterations)
    iterations.times() do
      (@height).times do |y|
        (@width).times do |x|
          if(empty_neighbors(x, y, 1) >= 5)
            set_is_solid(x, y, false)
          else
            set_is_solid(x, y, true)
          end
        end
      end
    end
  end

  # Counts the number of empty cells around a cell within a given radius
  def empty_neighbors (cell_x, cell_y, radius)
    empty_neighbors = 0
    x = cell_x - radius
    while(x <= cell_x + radius)
      y = cell_y - radius
      while(y <= cell_y + radius)
        if(is_within_map?(x, y) && !is_solid?(x, y))
          empty_neighbors += 1
        end
        y += 1
      end
      x += 1
    end
    return empty_neighbors
  end

  # ---------- ROGUE STYLE ----------

  def rogue_style(num_rooms, num_loops, min_room_width, max_room_width, min_room_height, max_room_height)
    timeout = 1000
    number_of_rooms = num_rooms
    fill_map(true)

    number_of_rooms.times() do

      valid_room, room_width, room_height, p_topright = nil
      loop_count = 0

      loop do
        valid_room = true
        room_width = rand(min_room_width..max_room_width)
        room_height = rand(min_room_height..max_room_height)
        p_topright = pick_random_point()

        if(!is_within_map?(p_topright[:x] + room_width, p_topright[:y] + room_height))
          valid_room = false
        end

        (room_width + 2).times do |w|
          (room_height + 2).times do |h|
            if (!is_within_map?(p_topright[:x] + w - 1, p_topright[:y] + h - 1) || !is_solid?(p_topright[:x] + w - 1, p_topright[:y] + h - 1))
              valid_room = false
            end
          end
        end

        loop_count += 1
        break if(valid_room || loop_count > timeout)
      end

      if(valid_room)
        room_width.times do |w|
          room_height.times do |h|
            set_is_solid(p_topright[:x] + w, p_topright[:y] + h, false)
          end
        end
      end

    end

    unconnected_rooms = count_rooms()[:rooms]

    count_rooms_attributes = count_rooms()
    while(count_rooms_attributes[:room_count] > 1)
      connect_rooms(count_rooms_attributes[:rooms])
      count_rooms_attributes = count_rooms()
    end

    num_loops.times() do
      connect_rooms(unconnected_rooms)
    end

  end

  # ---------- DRUNKARD'S WALK ----------

    def drunk_walk (steps, is_filling)
    x = (@width/2).floor()
    y = (@height/2).floor()
    set_is_solid(x, y, is_filling)
    (steps-1).times() do
      new_coordinates = random_step(x, y)
      while(!is_within_map?(new_coordinates[:x], new_coordinates[:y])) do
        new_coordinates = random_step(x, y)
      end
      x = new_coordinates[:x]
      y = new_coordinates[:y]
      set_is_solid(x, y, is_filling)
    end
  end

  def random_step (x, y)
    direction = rand(4)
    if(direction == 0)
      y -= 1
    elsif(direction == 2)
      y += 1
    elsif(direction == 3)
      x -= 1
    else
      x += 1
    end
    return {:x => x, :y => y}
  end

  # ---------- COUNTING AND CONNECTING ROOMS ----------

  def count_rooms
    room_count = 0
    rooms = Array.new(@width)
    rooms.each_index() do |index|
      rooms[index] = Array.new(@height, 0)
    end
    @map.each_index() do |x|
      @map[x].each_index() do |y|
        if(!is_solid?(x, y) && rooms[x][y] == 0)
          room_count += 1
          flood_fill(x, y, rooms, room_count)
        end
      end
    end
    return {:rooms => rooms, :room_count => room_count}
  end

  def flood_fill(x, y, rooms, fill_with)
    if (is_within_map?(x, y) && !is_solid?(x, y) && rooms[x][y] == 0)
      rooms[x][y] = fill_with
      flood_fill(x + 1, y, rooms, fill_with);
      flood_fill(x - 1, y, rooms, fill_with);
      flood_fill(x, y + 1, rooms, fill_with);
      flood_fill(x, y - 1, rooms, fill_with);
    end
  end

  def connect_rooms(rooms)

    # Pick two random points (P1 & P2) in different rooms.
    p1, p2 = nil
    loop do
      p1 = pick_random_point()
      break if((rooms[p1.fetch(:x)][p1.fetch(:y)] != 0))
    end
    loop do
      p2 = pick_random_point()
      break if(rooms[p2.fetch(:x)][p2.fetch(:y)] != 0 && rooms[p2.fetch(:x)][p2.fetch(:y)] != rooms[p1.fetch(:x)][p1.fetch(:y)])
    end

    # Get P1 as close as possible to P2 without leaving the room it's in.
    @map.each_index() do |x|
      @map[x].each_index() do |y|
        if(rooms[x][y] == rooms[p1.fetch(:x)][p1.fetch(:y)])
          if(distance_between_points(p1, p2) > distance_between_points({:x => x, :y => y}, p2))
            p1 = {:x => x, :y => y}
          end
        end
      end
    end

    # Get P2 as close as possible to P1 without leaving the room it's in.
    @map.each_index() do |x|
      @map[x].each_index() do |y|
        if(rooms[x][y] == rooms[p2.fetch(:x)][p2.fetch(:y)])
          if(distance_between_points(p1, p2) > distance_between_points(p1, {:x => x, :y => y}))
            p2 = {:x => x, :y => y}
          end
        end
      end
    end

    # Dig a tunnel between the two points.
    pdig = {:x => p1[:x], :y => p1[:y]}
    pdig = move_point_towards_point(pdig, p2)
    while(pdig != p2 && rooms[pdig.fetch(:x)][pdig.fetch(:y)] == 0)
      set_is_solid(pdig.fetch(:x), pdig.fetch(:y), false)
      pdig = move_point_towards_point(pdig, p2)
    end

  end

  def move_point_towards_point(move_point, towards_point)
    if(move_point[:x] < towards_point[:x])
      move_point.update({:x => move_point[:x] + 1})
    elsif(move_point[:x] > towards_point[:x])
      move_point.update({:x => move_point[:x] - 1})
    elsif(move_point[:y] < towards_point[:y])
      move_point.update({:y => move_point[:y] + 1})
    elsif(move_point[:y] > towards_point[:y])
      move_point.update({:y => move_point[:y] - 1})
    end
    return move_point
  end

  def get_room_size(rooms, room_number)
    room_size = 0
    @map.each_index() do |x|
      @map[x].each_index() do |y|
        if(rooms[x][y] == room_number)
          room_size += 1
        end
      end
    end
    return room_size
  end

  # ---------- MISC. UTILITY FUNCTIONS ----------

  def randomize_map
    @map.each_index() do |x|
      @map[x].each_index() do |y|
        set_is_solid(x, y, rand(2) == 0)
      end
    end
  end

  def fill_map (with_solid)
    @map.each_index() do |x|
      @map[x].each_index() do |y|
        set_is_solid(x, y, with_solid)
      end
    end
  end

  def create_boundaries
    @map.each_index() do |x|
      @map[x].each_index() do |y|
        if(x == 0 || y == 0 || x == @width-1 || y == @height-1)
          set_is_solid(x, y, true)
        end
      end
    end
  end

  def distance_between_points(p1, p2)
    v = Vector[p1.fetch(:x) - p2.fetch(:x), p1.fetch(:y) - p2.fetch(:y)]
    return v.magnitude()
  end

  def pick_random_point
    return {:x => rand(@width), :y => rand(@height)}
  end

  def is_within_map? (x, y)
    return x >= 0 && y >= 0 && x < @width && y < @height
  end

  def pick_random_empty_point
    point = nil
    loop do
      point = pick_random_point()
      break if(!is_solid?(point[:x], point[:y]))
    end
    return point
  end

  def is_solid? (x, y)
    return @map[x][y]
  end

  def set_is_solid (x, y, is_solid)
    @map[x][y] = is_solid
  end

  # BELOW FUNCTIONS FOR TESTING ONLY

  def print_map
    (@height).times do |y|
      (@width).times do |x|
        if(is_solid?(x, y))
          print("#")
        else
          print(".")
        end
      end
      print("\n")
    end
  end

end
