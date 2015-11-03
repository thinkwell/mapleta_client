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
          @correct_answer ||= correct_answer_thinkwell.length > 0 ? correct_answer_thinkwell : correct_answer_mapleta
        end

        def correct_answer_thinkwell
          # Try to get correct answer from feedback entered by Thinkwell and wrapped in <span class="correct-answer"></span>
          # not all questions will have this make sure you check. If it doesn't exist proceed with correct_answer_mapleta
          @correct_answer_thinkwell ||= content_node.xpath('//span[@class="correct-answer"]')
        end

        def correct_answer_mapleta
          # Detect a type of question first. Then run custom parse function for each.
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
          base.each{|node| node.remove_attribute('style'); node['class'] = 'correct-answer' } if base.length
          base
        end

        def multiple_response(html)
          answer = html.xpath('//th[contains(.,"Choice")]/../th[contains(.,"Selected")]/../th[contains(.,"Points")]/../..')
          answer = answer.xpath('//table/tr/th[contains(.,"Selected")]/../../tr/td/font/img[@src[contains(.,"images")]]/../../../td[1]')
          answer.each do |node|
            node.inner_html = '<span class="correct-answer">' + node.inner_html + '</span>'
          end
          answer
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
