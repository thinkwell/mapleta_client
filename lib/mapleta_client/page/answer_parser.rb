module Maple::MapleTA
  module Page

    module AnswerParser

      module ClassMethods

      end

      module InstanceMethods

        def answer_types
          [
            { :method => :free_response,
              :detect => '//th[contains(.,"Your response")]/../th[contains(.,"Correct response")]'
            },
            {
              :method => :multiple_response,
              :detect => '//th[contains(.,"Choice")]/../th[contains(.,"Selected")]/../th[contains(.,"Points")]'
            },
            {
              :method => :multiple_choice,
              :detect => '//td/b[text()="Correct Answer:"]'
            }
          ]
        end

        def correct_answer
          answers = []
          answer_types.each do |answer_type|
            if content_node.xpath(answer_type[:detect]).count > 0
              answers << self.send(answer_type[:method], content_node)
            end
          end
          answers.join('')
        end

        def free_response(html)
          base = html.xpath('//span[@style="background-color: #ccffcc"]')
          base.each{|node| node.remove_attribute('style')} if base.length
          base = base.xpath('.//tt/b/node()')
          case base.length
            when 2..100
              return base.to_a.join(', ')
            when 1
              return base
            else
              html.xpath('//span[@style="background-color: #ccffcc"]/../..')
          end
        end

        def multiple_response(html)
          answer = html.xpath('//th[contains(.,"Choice")]/../th[contains(.,"Selected")]/../th[contains(.,"Points")]/../..')
          answer = answer.xpath('//table/tr/th[contains(.,"Selected")]/../../tr/td/font/img[@src[contains(.,"images")]]/../../../td[1]')
          answer.each do |node|
            node.inner_html = '<li class="correct-answer-item">' + node.inner_html + '</li>'
          end
          '<ul>' + answer.xpath('.//li').to_html + '</ul>'
          #answer.select{|a| !a.text().blank?}.to_a.join(", ")
        end

        def multiple_choice(html)
          html.xpath('//td/b[text()="Correct Answer:"]/../../td[2]/node()')
        end

      end

      def self.included(base)
        base.send :include, InstanceMethods
        base.send :extend, ClassMethods

        attr_reader :correct_answer, :user_answer
      end

    end

  end
end
