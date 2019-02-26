module Jekyll
    def self.get_post(page_id_or_slug, posts)
        posts.docs.each do |post|
            if post.data['slug'] == page_id_or_slug or post.id == page_id_or_slug
                return post.url, post.data['title']
            end
        end
        puts "Warning: 页面未找到：" + page_id_or_slug
        return "", "页面未找到：" + page_id_or_slug
    end

    class RelatedTag < Liquid::Tag
        def initialize(tag_name, text, tokens, type)
            super(tag_name, text, tokens)
            @text = text.strip!
            @type = type
        end
  
        def render(context)
            if @text.empty?
                return "Error RelatedNote. Expected: {% related_note post_id %}"
            end
            
            url, title = Jekyll.get_post(@text, context.registers[:site].posts)

            "<div><a href='#{context.registers[:site].config['baseurl']}#{url}'><div class='alert alert-success'><i class='fas fa-pencil-alt'></i> 相关#{@type}：#{title}</div></a></div>"
        end
    end

    class RelatedNoteTag < RelatedTag
        def initialize(tag_name, text, tokens)
            super(tag_name, text, tokens, "笔记")
        end
    end

    class RelatedChallengeTag < RelatedTag
        def initialize(tag_name, text, tokens)
            super(tag_name, text, tokens, "题目")
        end
    end
end
  
Liquid::Template.register_tag('related_note', Jekyll::RelatedNoteTag)
Liquid::Template.register_tag('related_challenge', Jekyll::RelatedChallengeTag)
