module Jekyll
    module StripA
        def strip_a(input)
            input.gsub(/<a[^>]*>/, "").gsub(/<\/a>/, "")
        end
    end
end
  
Liquid::Template.register_filter(Jekyll::StripA)