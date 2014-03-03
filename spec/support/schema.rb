Sequel.migration do
  change do
    create_table(:author) do
      Integer :id, :null => false
      String :uid, :null => false
      String :instance, :null => false
      String :display_name, :size => 100, :null => false
      String :default_school, :null => false
      DateTime :created, :null => false
      String :created_by
      DateTime :modified
      String :modified_by
      
      primary_key [:uid]
    end
    
    create_table(:classes, :ignore_index_errors => true) do
      primary_key :cid
      String :name, :size => 255, :null => false
      Integer :instructorid
      TrueClass :deleted, :default => false
      TrueClass :featured, :default => false
      Date :creationdate
      foreign_key :parent, :classes, :key => [:cid], :on_delete => :restrict, :on_update => :restrict
      String :school, :size => 255
      String :descriptionurl, :size => 255
      String :dirname, :size => 255, :null => false
      TrueClass :visible, :default => true
      TrueClass :registrationlocked, :default => true, :null => false
      String :courseid, :size => 100
      String :uid
      String :original_instance
      DateTime :lastmodified, :default => Sequel::CURRENT_TIMESTAMP, :null => false
      
      index [:name], :name => :uk_name, :unique => true
    end
    
    create_table(:essay_symbol) do
      primary_key :id
      String :symbol, :size => 10, :null => false
      String :description, :text => true, :null => false
      DateTime :created, :null => false
      String :created_by
      DateTime :modified
      String :modified_by
    end
    
    create_table(:instance) do
      Integer :id, :null => false
      String :uid, :null => false
      String :url, :size => 255, :null => false
      String :name, :size => 100, :null => false
      TrueClass :publish_to, :default => true, :null => false
      TrueClass :receive_from, :default => true, :null => false
      DateTime :created, :null => false
      String :created_by, :null => false
      DateTime :modified
      String :modified_by
      
      primary_key [:uid]
    end
    
    create_table(:roles) do
      Integer :id, :null => false
      String :role, :size => 255, :null => false
      
      primary_key [:id]
    end
    
    create_table(:school) do
      Integer :id, :null => false
      String :uid, :null => false
      String :parent
      String :name, :size => 255, :null => false
      DateTime :created, :null => false
      String :created_by
      DateTime :modified
      String :modified_by
      
      primary_key [:uid]
    end
    
    create_table(:subject) do
      Integer :id, :null => false
      String :uid, :null => false
      foreign_key :parent, :subject, :type => String, :key => [:uid]
      DateTime :created, :null => false
      String :created_by
      DateTime :modified
      String :modified_by
      
      primary_key [:uid]
    end
    
    create_table(:system_properties) do
      String :key, :size => 255, :null => false
      String :value, :size => 4000, :null => false
      String :group, :size => 20
      
      primary_key [:key]
    end
    
    create_table(:usage) do
      Integer :id, :null => false
      DateTime :log_time, :null => false
      Integer :count, :default => 0, :null => false
      Integer :started_assignments, :default => 0, :null => false
      Integer :finished_assignments, :default => 0, :null => false
      TrueClass :restart, :default => false, :null => false
      Integer :logins, :default => 0, :null => false
    end
    
    create_table(:assignment, :ignore_index_errors => true) do
      primary_key :id
      foreign_key :classid, :classes, :null => false, :key => [:cid]
      String :name, :size => 255, :null => false
      Float :weighting, :null => false
      Float :totalpoints
      DateTime :lastmodified, :null => false
      String :uid, :size => 50
      TrueClass :adaptive, :default => false, :null => false
      
      index [:classid], :name => :fk_assignment_classid
      index [:uid], :name => :idx_assignment_uid
    end
    
    create_table(:class_subject) do
      foreign_key :cid, :classes, :null => false, :key => [:cid], :on_delete => :restrict, :on_update => :restrict
      foreign_key :subject, :subject, :type => String, :null => false, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      DateTime :created, :null => false
      String :created_by, :null => false
      
      primary_key [:cid, :subject]
    end
    
    create_table(:external_assignment) do
      primary_key :id
      foreign_key :classid, :classes, :null => false, :key => [:cid], :on_delete => :restrict, :on_update => :restrict
      String :name, :size => 255, :null => false
      Float :weighting, :null => false
      Float :totalpoints, :null => false
      DateTime :lastmodified, :null => false
    end
    
    create_table(:question_group, :ignore_index_errors => true) do
      primary_key :id
      String :name, :null => false
      foreign_key :creator, :classes, :null => false, :key => [:cid], :on_delete => :restrict, :on_update => :restrict
      DateTime :created, :null => false
      TrueClass :private, :default => true, :null => false
      Integer :count, :default => 0, :null => false
      foreign_key :parent, :question_group, :key => [:id]
      String :uid
      String :cloned_from
      String :cloned_from_instance
      String :created_by
      String :description, :text => true
      DateTime :modified
      String :modified_by
      DateTime :last_published
      Integer :privacy, :default => 0, :null => false
      
      index [:uid], :name => :question_group_uid_unique, :unique => true
    end
    
    create_table(:question_header) do
      Integer :id, :null => false
      String :uid, :null => false
      String :name, :default => "", :null => false
      String :cloned_from
      String :cloned_from_instance
      foreign_key :class_id, :classes, :null => false, :key => [:cid]
      String :current_revision_uid
      DateTime :created, :null => false
      String :created_by
      DateTime :modified
      String :modified_by
      TrueClass :allow_republish, :default => true, :null => false
      TrueClass :allow_publish, :default => true, :null => false
      Float :difficulty, :default => 0.0
      String :language, :size => 2, :fixed => true
      String :tags
      String :description
      String :info
      TrueClass :deleted, :default => false, :null => false
      Integer :privacy, :default => 0, :null => false
      DateTime :last_published
      Integer :weight, :default => 0, :null => false
      
      primary_key [:uid]
    end
    
    create_table(:snapshot) do
      primary_key :id
      String :name, :default => "", :size => 25, :null => false
      foreign_key :classid, :classes, :null => false, :key => [:cid]
      TrueClass :visible, :default => false, :null => false
      TrueClass :show_instructors, :default => false, :null => false
      TrueClass :show_proctors, :default => false, :null => false
      TrueClass :show_students, :default => true, :null => false
      Integer :user_list, :default => 0, :null => false
    end
    
    create_table(:subject_name) do
      primary_key :id
      foreign_key :subject, :subject, :type => String, :null => false, :key => [:uid]
      String :name, :size => 100, :null => false
      String :language, :default => "en", :size => 2, :fixed => true, :null => false
      DateTime :created, :null => false
      String :created_by
      DateTime :modified
      String :modified_by
    end
    
    create_table(:user_profiles, :ignore_index_errors => true) do
      primary_key :id
      String :uid, :size => 255, :null => false
      String :givenname, :size => 255, :null => false
      String :sn, :size => 255, :null => false
      String :userpassword, :size => 255
      String :email, :size => 255
      DateTime :lastlogin
      String :cn, :size => 255
      String :mi, :size => 1
      String :student_id, :size => 100
      String :challenge, :size => 255
      String :response, :size => 255
      Integer :disabled, :default => 0, :null => false
      Integer :validated, :default => 0, :null => false
      Integer :deleted, :default => 0, :null => false
      foreign_key :author, :author, :type => String, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      
      index [:email], :name => :unq_email, :unique => true
      index [:student_id], :name => :unq_student_id, :unique => true
      index [:uid], :name => :unq_user_name, :unique => true
    end
    
    create_table(:adaptive_assignment_policy_basic) do
      Integer :increase_difficulty, :default => 0, :null => false
      Integer :decrease_difficulty, :default => 0, :null => false
      TrueClass :increase_difficulty_streak, :default => false
      TrueClass :decrease_difficulty_streak, :default => false, :null => false
      foreign_key :assignment_id, :assignment, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      TrueClass :exit_on_questions_seen, :default => false, :null => false
      TrueClass :exit_on_questions_correct, :default => false, :null => false
      TrueClass :exit_on_questions_incorrect, :default => false, :null => false
      Integer :exit_questions_seen, :default => 0, :null => false
      Integer :exit_questions_correct, :default => 0, :null => false
      Integer :exit_questions_incorrect, :default => 0, :null => false
      Integer :branch_complete, :default => 0, :null => false
      String :algorithm, :text => true
      Integer :adaptive_policy, :default => 0, :null => false
      Integer :grade_policy, :default => 0, :null => false
      
      primary_key [:assignment_id]
    end
    
    create_table(:assignment_branch) do
      primary_key :id
      foreign_key :assignmentid, :assignment, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      Integer :order_id, :default => 0, :null => false
      String :name, :text => true, :null => false
      Float :weight, :default => 1.0
      TrueClass :scrambled, :default => false
      TrueClass :recycle, :default => false
      TrueClass :startingbranch, :default => false
    end
    
    create_table(:assignment_class, :ignore_index_errors => true) do
      primary_key :id
      foreign_key :classid, :classes, :null => false, :key => [:cid]
      foreign_key :assignmentid, :assignment, :null => false, :key => [:id]
      String :name, :size => 255, :null => false
      Integer :order_id, :null => false
      Float :totalpoints
      Float :weighting, :null => false
      DateTime :lastmodified, :null => false
      foreign_key :parent, :assignment_class, :key => [:id]
      
      index [:assignmentid], :name => :fki_assignment_class_assignmentid
      index [:classid], :name => :fki_assignment_class_classid
      index [:parent], :name => :fki_assignment_class_parent
    end
    
    create_table(:external_testrecord) do
      primary_key :id
      foreign_key :externalassignmentid, :external_assignment, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      foreign_key :userid, :user_profiles, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      Float :score, :null => false
      foreign_key :classid, :classes, :null => false, :key => [:cid], :on_delete => :restrict, :on_update => :restrict
      Float :passingscore
      DateTime :date, :null => false
      foreign_key :addedby, :user_profiles, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      String :comment, :text => true
    end
    
    create_table(:privileges) do
      foreign_key :user_id, :user_profiles, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      foreign_key :role_id, :roles, :null => false, :key => [:id]
      TrueClass :insertuser, :default => false, :null => false
      TrueClass :modifyuser, :default => false, :null => false
      TrueClass :deleteuser, :default => false, :null => false
      TrueClass :viewuser, :default => false, :null => false
      TrueClass :insertclass, :default => false, :null => false
      TrueClass :modifyclass, :default => false, :null => false
      TrueClass :deleteclass, :default => false, :null => false
      TrueClass :viewclass, :default => false, :null => false
      
      primary_key [:user_id]
    end
    
    create_table(:question, :ignore_index_errors => true) do
      primary_key :id
      String :name, :null => false
      String :mode, :null => false
      String :questiontext, :text => true, :null => false
      String :questionfields, :text => true, :null => false
      TrueClass :private, :default => true, :null => false
      foreign_key :author, :classes, :null => false, :key => [:cid], :on_delete => :restrict, :on_update => :restrict
      DateTime :created, :null => false
      String :algorithm, :text => true, :null => false
      String :description, :null => false
      String :hint, :text => true, :null => false
      String :comment, :text => true, :null => false
      String :info, :text => true, :null => false
      String :solution, :text => true, :null => false
      DateTime :lastmodified, :null => false
      String :annotation, :text => true, :null => false
      String :modedescription, :null => false
      String :tags, :null => false
      TrueClass :deleted, :default => false, :null => false
      foreign_key :latestrevision, :question, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      foreign_key :uid, :question_header, :type => String, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      String :modified_by
      String :revision
      TrueClass :attribute_author, :default => true, :null => false
      String :school
      
      index [:latestrevision], :name => :fki_question_latestrevision
      index [:author], :name => :fki_question_user
      index [:uid], :name => :idx_question_uid
    end
    
    create_table(:question_comment) do
      Integer :id, :null => false
      String :uid, :null => false
      foreign_key :question, :question_header, :type => String, :null => false, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      foreign_key :author, :author, :type => String, :null => false, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      String :value, :text => true, :null => false
      DateTime :created, :null => false
      String :created_by, :null => false
      DateTime :modified
      String :modified_by
      
      primary_key [:uid]
    end
    
    create_table(:question_group_subject) do
      foreign_key :question_group, :question_group, :type => String, :null => false, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      foreign_key :subject, :subject, :type => String, :null => false, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      DateTime :created, :null => false
      String :created_by, :null => false
      
      primary_key [:question_group, :subject]
    end
    
    create_table(:question_rating) do
      Integer :id, :null => false
      String :uid, :null => false
      foreign_key :question, :question_header, :type => String, :null => false, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      foreign_key :author, :author, :type => String, :null => false, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      Integer :value, :null => false
      DateTime :created, :null => false
      String :created_by, :null => false
      DateTime :modified
      String :modified_by
      
      primary_key [:uid]
    end
    
    create_table(:question_subject) do
      foreign_key :question, :question_header, :type => String, :null => false, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      foreign_key :subject, :subject, :type => String, :null => false, :key => [:uid], :on_delete => :restrict, :on_update => :restrict
      DateTime :created, :null => false
      String :created_by, :null => false
      
      primary_key [:question, :subject]
    end
    
    create_table(:snapshot_group) do
      primary_key :id
      String :name, :default => "", :size => 25, :null => false
      Float :weight, :default => 0.0, :null => false
      TrueClass :equal_weight, :null => false
      Integer :drop, :default => 0, :null => false
      Integer :use, :default => 0, :null => false
      foreign_key :snapshotid, :snapshot, :null => false, :key => [:id]
      Integer :order, :default => 0, :null => false
      TrueClass :ignore_empty, :default => false, :null => false
      TrueClass :bonus, :default => false, :null => false
    end
    
    create_table(:student_assignment_permissions, :ignore_index_errors => true) do
      primary_key :id
      foreign_key :userid, :user_profiles, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      foreign_key :assignmentid, :assignment, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      Integer :actionallowed, :null => false
      foreign_key :authorizinguser, :user_profiles, :key => [:id]
      Date :permissiondate, :null => false
      foreign_key :classid, :classes, :null => false, :key => [:cid]
      DateTime :end_time
      Integer :time_limit, :default => -1
      
      index [:authorizinguser], :name => :fki_authorizing_user
    end
    
    create_table(:testrecord, :ignore_index_errors => true) do
      primary_key :id
      foreign_key :assignmentid, :assignment, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      foreign_key :userid, :user_profiles, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      TrueClass :active
      Bignum :duration
      TrueClass :fullygraded, :default => false
      TrueClass :ispassfail
      DateTime :edited
      DateTime :expiry
      DateTime :lastaction
      DateTime :start
      Float :score
      Integer :mode, :null => false
      foreign_key :proctor, :user_profiles, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      File :gradeproperties
      String :remoteaddress
      Integer :lastquestionworked
      Integer :gradetype
      Integer :passingscore
      foreign_key :classid, :classes, :null => false, :key => [:cid], :on_delete => :restrict, :on_update => :restrict
      String :externaldata
      
      index [:classid, :assignmentid], :name => :idx_testrecord_class_assignment
      index [:classid, :assignmentid, :active], :name => :idx_testrecord_class_assignment_active
    end
    
    create_table(:user_classes) do
      primary_key :id
      foreign_key :classid, :classes, :null => false, :key => [:cid], :on_delete => :restrict, :on_update => :restrict
      foreign_key :roleid, :roles, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      foreign_key :userid, :user_profiles, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      String :external_role, :size => 10
    end
    
    create_table(:answersheetitem, :ignore_index_errors => true) do
      primary_key :id
      String :tblocation, :size => 255, :null => false
      Integer :topic, :null => false
      Integer :question, :null => false
      Integer :questiongroup, :null => false
      Integer :questionref, :null => false
      String :serializedresponse, :text => true
      String :serializedversion, :text => true
      Float :grade
      String :comment, :text => true
      Integer :weighting
      String :questiontype, :size => 255
      String :searchableresponsestring, :text => true
      Integer :lastquestionworked
      foreign_key :testrecordid, :testrecord, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      Integer :questionindex, :null => false
      TrueClass :wrong, :default => true, :null => false
      Integer :branch
      Integer :branchindex
      Integer :adaptive_action, :default => 0
      Float :branchweight, :default => 1.0
      Float :difficulty, :default => 0.0
      String :grade_error, :text => true
      String :serializedannotatedresponse, :text => true
      
      index [:testrecordid], :name => :fki_testrecord
      index [:question], :name => :idx_answersheetitem_question
    end
    
    create_table(:assignment_advanced_policy, :ignore_index_errors => true) do
      foreign_key :assignment_class_id, :assignment_class, :null => false, :key => [:id]
      Integer :and_id, :null => false
      Integer :or_id, :null => false
      Integer :keyword, :null => false
      foreign_key :assignment_id, :assignment, :null => false, :key => [:id]
      TrueClass :has, :null => false
      
      primary_key [:assignment_class_id, :and_id, :or_id]
      
      index [:assignment_class_id], :name => :fki_assignment_advanced_policy_assignment_class_id
      index [:assignment_id], :name => :fki_assignment_advanced_policy_assignment_id
    end
    
    create_table(:assignment_mastery_penalty, :ignore_index_errors => true) do
      foreign_key :assignment_class_id, :assignment_class, :null => false, :key => [:id]
      Integer :group_id, :null => false
      Integer :wrong_answers_allowed, :null => false
      
      primary_key [:assignment_class_id, :group_id]
      
      index [:assignment_class_id], :name => :fki_assignment_mastery_penalty_assignment_class_id
    end
    
    create_table(:assignment_mastery_policy, :ignore_index_errors => true) do
      foreign_key :assignment_class_id, :assignment_class, :null => false, :key => [:id]
      Integer :complete_group_id, :null => false
      Integer :before_group_id, :null => false
      
      primary_key [:assignment_class_id, :complete_group_id, :before_group_id]
      
      index [:assignment_class_id], :name => :fki_assignment_mastery_policy_assignment_class_id
    end
    
    create_table(:assignment_policy, :ignore_index_errors => true) do
      foreign_key :assignment_class_id, :assignment_class, :null => false, :key => [:id]
      TrueClass :questions_scrambled, :default => false, :null => false
      String :header_text
      String :exit_text
      String :pass_feedback
      String :fail_feedback
      TrueClass :email_notified, :default => false, :null => false
      String :email, :size => 255
      String :show_final_grade_feedback
      String :no_final_grade_feedback
      Integer :mode, :default => 1, :null => false
      TrueClass :visible, :default => true, :null => false
      Integer :passing_score, :default => -1, :null => false
      Integer :time_limit, :default => -1, :null => false
      Integer :questions_per_page, :default => 1, :null => false
      TrueClass :printable, :default => false, :null => false
      TrueClass :start_authorization_required, :default => false, :null => false
      TrueClass :reworkable, :default => false, :null => false
      DateTime :start_time
      DateTime :end_time
      TrueClass :force_grade, :default => false, :null => false
      Integer :insession_comment, :default => 0, :null => false
      Integer :insession_answer, :default => 3, :null => false
      TrueClass :insession_grade, :default => true, :null => false
      TrueClass :insession_hints, :default => false, :null => false
      Integer :final_comment, :default => 0, :null => false
      Integer :final_answer, :default => 3, :null => false
      TrueClass :final_grade, :default => true, :null => false
      TrueClass :final_feedback_delayed, :default => false, :null => false
      DateTime :final_feedback_date
      Integer :final_pass_fail, :default => 4, :null => false
      TrueClass :use_lockdown, :default => false, :null => false
      Integer :lockdown_calculator, :default => 0, :null => false
      TrueClass :show_current_grade, :default => false, :null => false
      TrueClass :allow_resubmit_question, :default => true, :null => false
      String :ip_restrictions, :default => "", :size => 500, :null => false
      TrueClass :targeted, :default => false, :null => false
      TrueClass :one_hint, :default => false
      TrueClass :visible_time_range, :default => false, :null => false
      TrueClass :visible_advanced_policy, :default => false, :null => false
      TrueClass :reuse_algorithmic_variables, :default => false, :null => false
      Integer :scramble, :default => 0, :null => false
      TrueClass :show_adaptive_progress, :default => false, :null => false
      
      primary_key [:assignment_class_id]
      
      index [:assignment_class_id], :name => :fki_assignment_policy_assignment_class_id
    end
    
    create_table(:assignment_question_group, :ignore_index_errors => true) do
      primary_key :id
      foreign_key :assignmentid, :assignment, :null => false, :key => [:id]
      String :name, :default => "_", :null => false
      Integer :questions_to_pick, :default => 1, :null => false
      Integer :weighting, :default => 1, :null => false
      Integer :order_id, :null => false
      foreign_key :assignment_branch_id, :assignment_branch, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      Integer :assignment_branch_order_id
      
      index [:assignmentid], :name => :fki_assignment_question_group_assignmentid
    end
    
    create_table(:hints, :ignore_index_errors => true) do
      primary_key :id
      foreign_key :questionid, :question, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      String :hint, :text => true
      DateTime :modified, :null => false
      Float :penalty, :default => 0.0
      String :name, :size => 100, :null => false
      String :description, :text => true, :null => false
      Integer :orderid
      
      index [:questionid], :name => :fki_hints
    end
    
    create_table(:question_group_map, :ignore_index_errors => true) do
      primary_key :id
      foreign_key :questionid, :question, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      foreign_key :questiongroupid, :question_group, :null => false, :key => [:id]
      TrueClass :shadow, :default => false, :null => false
      String :question_uid
      
      index [:questionid], :name => :fki_question_group_map_question
      index [:questiongroupid], :name => :fki_question_group_map_question_group
      index [:questionid, :questiongroupid], :name => :unique_question_group_map, :unique => true
    end
    
    create_table(:snapshot_group_assignment_map) do
      primary_key :id
      foreign_key :assignmentid, :assignment, :null => false, :key => [:id]
      foreign_key :snapshot_groupid, :snapshot_group, :null => false, :key => [:id]
    end
    
    create_table(:snapshot_group_external_map) do
      primary_key :id
      foreign_key :externalid, :external_assignment, :null => false, :key => [:id]
      foreign_key :snapshot_groupid, :snapshot_group, :null => false, :key => [:id]
    end
    
    create_table(:answersheetitem_grade, :ignore_index_errors => true) do
      primary_key :id
      Float :grade, :null => false
      DateTime :modified, :null => false
      String :comment, :text => true
      foreign_key :userid, :user_profiles, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      foreign_key :answersheetitemid, :answersheetitem, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      
      index [:answersheetitemid], :name => :fki_answersheetitem
    end
    
    create_table(:assignment_question_group_map, :ignore_index_errors => true) do
      primary_key :id
      foreign_key :groupid, :assignment_question_group, :null => false, :key => [:id]
      foreign_key :questionid, :question, :null => false, :key => [:id]
      String :annotation
      Integer :annotation_position, :default => 0
      Integer :order_id
      String :question_uid
      
      index [:groupid], :name => :fki_assignment_question_group_map_groupid
      index [:questionid], :name => :fki_assignment_question_group_map_questionid
    end
    
    create_table(:hint_penalty, :ignore_index_errors => true) do
      primary_key :id
      foreign_key :answersheetitemid, :answersheetitem, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      foreign_key :hintid, :hints, :null => false, :key => [:id], :on_delete => :restrict, :on_update => :restrict
      DateTime :modified, :null => false
      
      index [:answersheetitemid], :name => :fki_hint_penalty_answersheetitem_id
      index [:hintid], :name => :fki_hint_penalty_hint_id
    end
  end
end
