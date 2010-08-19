require 'minitest/spec'
MiniTest::Unit.autorun
require 'set'
require 'fileutils'

testdir = File.dirname(__FILE__)
libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require 'document_file'

describe DocumentFile do
  before do
    DocumentFile.documents_dir = testdir + '/documents'
  end

  describe 'when finding all document_files' do
    before do
      @document_files = DocumentFile.all
    end

    it 'should return an Array' do
      assert_equal Array, @document_files.class
    end
  
    it "should find all document_files" do
      assert_equal 2, @document_files.size
    end
  end

  describe 'when initializing a DocumentFile' do
    before do
      @document_file = DocumentFile.new(testdir + '/documents/2010-08-08-test-document-file.textile')
    end

    it 'should initialize the content' do
      assert_equal "I like the flowers.\n", @document_file.content
    end

    it 'should intitialize strings from the front matter' do
      assert_equal String, @document_file.title.class
      assert_equal 'The shizzle!', @document_file.title
    end

    it 'should intitialize strings from the front matter' do
      assert_equal Array, @document_file.tags.class
      assert_equal ['tag'], @document_file.tags
    end

    it 'should intitialize integers from the front matter' do
      assert_equal Fixnum, @document_file.number_of_foos.class
      assert_equal 42, @document_file.number_of_foos
    end
  end

  describe 'when listing document_files by an array attribute' do
    it 'should return a Hash' do
      assert_equal Hash, DocumentFile.by_tags.class
    end

    it 'should use the tags as Hash keys' do
      assert_equal Set.new(['tag', 'tug']), DocumentFile.by_tags.keys.to_set
    end

    it 'should use the document_files as Hash values' do
      document_files = DocumentFile.by_tags
      assert_equal Set.new([1, 2]), document_files['tag'].map(&:id).to_set
      assert_equal Set.new([2]), document_files['tug'].map(&:id).to_set
    end
  end

  describe 'when finding a document_file' do
    it 'should find the right document_file by an attribute' do
      title = 'The shizzle!'
      document_file = DocumentFile.find_by_title(title)
      assert_equal title, document_file.title
    end

    it 'should find the right document_file by file_name' do
      file_name = '2010-08-08-test-document-file'
      document_file = DocumentFile.find_by_file_name file_name
      assert_equal document_file.file_name, file_name
    end
  end

  describe 'when getting the file name or file path' do
    it 'should show the right file name' do
      document_file = DocumentFile.new './test/documents/2010-08-08-test-document-file.textile'
      file_name = '2010-08-08-test-document-file'
      assert_equal file_name, document_file.file_name
    end

    it 'should show the right file name with extension' do
      document_file = DocumentFile.new './test/documents/2010-08-08-test-document-file.textile'
      file_name = '2010-08-08-test-document-file.textile'
      assert_equal file_name, document_file.file_name_with_extension
    end

    it 'should show the right extension' do
      document_file = DocumentFile.new './test/documents/2010-08-08-test-document-file.textile'
      extension = '.textile'
      assert_equal extension, document_file.file_extension
    end

    it 'should show the right file path' do
      file_path = './test/documents/2010-08-08-test-document-file.textile'
      document_file = DocumentFile.new file_path
      assert_equal file_path, document_file.file_path
    end
  end

  describe 'when calling a method that was not defined dynamically' do
    it 'should throw an error on the class level' do
      assert_raises(NoMethodError) { DocumentFile.hululu }
    end

    it 'should throw an error on the instance level' do
      document_file = DocumentFile.new('./test/documents/2010-08-08-test-document-file.textile')
      assert_raises(NoMethodError) { document_file.hululu }
    end
  end

  describe 'when reloading all document_files' do
    before do
      @default_dir = testdir + '/documents'
      DocumentFile.documents_dir = @default_dir
      DocumentFile.reload!
      @document_files_before = DocumentFile.all
      @tmp_dir = "#{@default_dir}-#{Time.now.to_i}-#{rand(999999)}-test"
      FileUtils.cp_r @default_dir, @tmp_dir
    end

    after do
      FileUtils.rm_r(@tmp_dir) if Dir.exist?(@tmp_dir)
    end

    it 'should get updated document_files' do
      updated_document_file = <<-eos
---
id: 1
title: The shuzzle!
tags: [tig]
number_of_foos: 48
---

I like the foos.
eos
      document_file_file_name = "#{@tmp_dir}/2010-08-08-test-document-file.textile"
      File.open(document_file_file_name, 'w') {|f| f.write(updated_document_file) }
      DocumentFile.documents_dir = @tmp_dir
      DocumentFile.reload!
      document_files_after = DocumentFile.all

      assert_equal @document_files_before.first.id, document_files_after.first.id
      refute_equal @document_files_before.first.title, document_files_after.first.title
      refute_equal @document_files_before.first.tags, document_files_after.first.tags
      refute_equal @document_files_before.first.number_of_foos, document_files_after.first.number_of_foos
      refute_equal @document_files_before.first.content, document_files_after.first.content
    end

    it 'should get new document_files' do
      new_document_file = <<-eos
---
id: 3
title: The shuzzle!
tags: [tig]
number_of_foos: 48
---

I like the cows.
eos
      document_file_file_name = "#{@tmp_dir}/2010-08-15-new-test-document_file.textile"
      File.open(document_file_file_name, 'w') {|f| f.write(new_document_file) }
      DocumentFile.documents_dir = @tmp_dir
      DocumentFile.reload!
      document_files_after = DocumentFile.all

      assert_equal @document_files_before.size + 1, document_files_after.size
      assert_equal 'The shuzzle!', document_files_after.last.title
      assert_equal "I like the cows.\n", document_files_after.last.content
    end

    it 'should not change if no document_files were changed' do
      DocumentFile.reload!
      document_files_after = DocumentFile.all
      assert_equal @document_files_before.map(&:id), document_files_after.map(&:id)
    end

    it 'should not show deleted document_files' do
      document_file_file_name = "#{@tmp_dir}/2010-08-08-test-document-file.textile"
      FileUtils.rm document_file_file_name
      DocumentFile.documents_dir = @tmp_dir
      DocumentFile.reload!
      document_files_after = DocumentFile.all
      refute_equal @document_files_before.map(&:id), document_files_after.map(&:id)
    end
  end
end
