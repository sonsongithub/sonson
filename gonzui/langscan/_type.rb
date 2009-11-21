#
# _type.rb - a part of LangScan
#
# Copyright (C) 2004-2005 Satoru Takabayashi <satoru@namazu.org> 
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

module LangScan
  module Type
    def self.N_ (dummy); dummy; end

    class TypeGroup
      def initialize(name)
        @name = name
        @members = []
        @by_type = {}
      end
      attr_reader :name

      def << (info)
        @members.push(info)
        @by_type[info.type] = info
      end

      def has_type?(type)
        @by_type.include?(type)
      end

      def each
        @members.each {|info| yield(info) }
      end

      def [] (i)
        if i.is_a?(Integer)
          @members[i]
        else
          @by_type[i]
        end
      end
    end

    TypeRegistry = {}

    class TypeInfo
      def initialize(type, name)
        @type = type
        @name = name
        TypeRegistry[@type] = true
      end
      attr_reader :type
      attr_reader :name
    end

    FunctionGroup = TypeGroup.new(N_("Function"))
    FunctionGroup << TypeInfo.new(:fundef,  N_("Function Definition"))
    FunctionGroup << TypeInfo.new(:funcall, N_("Function Call"))
    FunctionGroup << TypeInfo.new(:fundecl, N_("Function Declaration"))

    ObjectGroup = TypeGroup.new(N_("Object"))
    ObjectGroup << TypeInfo.new(:classdef,  N_("Class Definition"))
    ObjectGroup << TypeInfo.new(:classref,  N_("Class Reference"))
    ObjectGroup << TypeInfo.new(:moduledef, N_("Module Definition"))

    LiteralGroup = TypeGroup.new(N_("Literal"))
    LiteralGroup << TypeInfo.new(:const,     N_("Constant"))
    LiteralGroup << TypeInfo.new(:word,      N_("Word"))
    LiteralGroup << TypeInfo.new(:ident,     N_("Identifier"))
    LiteralGroup << TypeInfo.new(:integer,   N_("Integer"))
    LiteralGroup << TypeInfo.new(:floating,  N_("Floating"))
    LiteralGroup << TypeInfo.new(:imaginary, N_("Imaginary"))
    LiteralGroup << TypeInfo.new(:string,    N_("String"))
    LiteralGroup << TypeInfo.new(:symbol,    N_("Symbol"))
    LiteralGroup << TypeInfo.new(:character, N_("Character"))
    LiteralGroup << TypeInfo.new(:comment,   N_("Comment"))

    KeywordGroup = TypeGroup.new(N_("Keyword"))
    KeywordGroup << TypeInfo.new(:keyword, N_("Keyword"))
    KeywordGroup << TypeInfo.new(:type,    N_("Primitive Type"))

    TextGroup = TypeGroup.new(N_("Text"))
    TextGroup << TypeInfo.new(:text, N_("Text"))

    AllGroups = [
      FunctionGroup, ObjectGroup, LiteralGroup, 
      KeywordGroup, TextGroup
    ]

    module_function
    def function?(type)
      FunctionGroup.has_type?(type)
    end

    def include?(type)
      TypeRegistry.include?(type)
    end

    SplittableTypes = {}
    [:string, :comment, :text].each {|type| SplittableTypes[type] = true }
    def splittable?(type)
      SplittableTypes.include?(type)
    end

    def highlightable?(type)
      ! splittable?(type)
    end

    def each_group
      AllGroups.each {|group|
        yield(group)
      }
    end

    def each
      each_group {|group|
        group.each {|info|
          yield(info)
        }
      }
    end
  end
end
