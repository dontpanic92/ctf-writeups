module Jekyll
    class UrlBySlug < Liquid::Tag
        def initialize(tag_name, text, tokens)
            super
            @text = text.strip!
        end
  
        def get_post_url(page_slug, posts)
            posts.docs.each do |post|
                if post.data['slug'] == page_slug
                    return post.url
                end
            end
            puts "Warning: 页面未找到：" + page_slug
            return "页面未找到：" + page_slug
        end

        def render(context)
            if @text.empty?
                return "Error UrlBySlug. Expected: {% url_by_slug post_slug %}"
            end
            
            self.get_post_url(@text, context.registers[:site].posts)
        end
    end
end
  
Liquid::Template.register_tag('url_by_slug', Jekyll::UrlBySlug)