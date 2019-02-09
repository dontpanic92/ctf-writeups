module Jekyll
    def self.get_post(page_slug, posts)
        posts.docs.each do |post|
            if post.data['slug'] == page_slug
                return post.url, post.data['title']
            end
        end
        return "", "页面未找到：" + page_slug
    end

    class RelatedNoteTag < Liquid::Tag
        def initialize(tag_name, text, tokens)
            super
            @text = text.strip!
        end
  
        def render(context)
            if @text.empty?
                return "Error RelatedNote. Expected: {% related_note post_id %}"
            end
            
            url, title = Jekyll.get_post(@text, context.registers[:site].posts)

            "<div><a href='#{context.registers[:site].config['baseurl']}#{url}'><div class='alert alert-success'><i class='fas fa-pencil-alt'></i> 相关笔记：#{title}</div></a></div>"
        end
    end
end
  
Liquid::Template.register_tag('related_note', Jekyll::RelatedNoteTag)
