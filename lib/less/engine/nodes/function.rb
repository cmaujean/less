module Less
  #
  # Functions useable from within the style-sheet go here
  #
  module Functions
    def rgb *rgb
      rgba rgb, 1.0
    end

    def hsl *args
      hsla args, 1.0
    end

    #
    # RGBA to Node::Color
    #
    def rgba *rgba
      r, g, b, a = rgba.flatten
      hex = [r, g, b].inject("") do |str, c|
        c = c.to_i.to_s(16)
        c = '0' + c if c.length < 2
        str + c
      end
      Node::Color.new hex, a
    end
    
    #
    # HSLA to RGBA
    #
    def hsla h, s, l, a = 1.0
      m2 = ( l <= 0.5 ) ? l * ( s + 1 ) : l + s - l * s
      m1 = l * 2 - m2;

      hue = lambda do |h|
        h = h < 0 ? h + 1 : (h > 1 ? h - 1 : h)
        if    h * 6 < 1 then m1 + (m2 - m1) * h * 6
        elsif h * 2 < 1 then m2 
        elsif h * 3 < 2 then m1 + (m2 - m1) * (2/3 - h) * 6 
        else m1
        end
      end

      rgba hue[ h + 1/3 ], hue[ h ], hue[ h - 1/3 ], a
    end
  end
  
  module Node
    #
    # A CSS function, like rgb() or url()
    #
    #   it calls functions from the Functions module
    #
    class Function < ::String
      include Functions
      include Entity
    
      def initialize name, *args
        @args = args.flatten
        super name
      end
    
      def to_css
        self.evaluate.to_css
      end
      
      #
      # Call the function
      #
      def evaluate
        send self.to_sym, *@args
      end
      
      #
      # If the function isn't found, we just print it out,
      # this is the case for url(), for example,
      #
      def method_missing meth, *args
        Node::Anonymous.new("#{meth}(#{args.map(&:to_css) * ', '})")
      end
    end
  end
end