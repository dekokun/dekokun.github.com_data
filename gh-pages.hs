{-# LANGUAGE OverloadedStrings #-}
module Main where

import Prelude hiding (id)
import Control.Category (id)
import Control.Arrow ((>>>), (***), arr)
import Data.Monoid (mempty, mconcat)

import Hakyll

main :: IO ()
main = hakyllWith config $ do
    -- Compress CSS
    _ <- ($)
        match "css/*" $ do
            route idRoute
            compile compressCssCompiler

    -- Render posts
    _ <- ($)
        match "posts/*" $ do
            route $ setExtension ".html"
            compile $ pageCompiler
                >>> renderTagsField "prettytags" (fromCapture "tags/*")
                >>> arr (setField "blogTitle" blogTitle)
                >>> applyTemplateCompiler "templates/post.html"
                >>> applyTemplateCompiler "templates/default.html"
                >>> relativizeUrlsCompiler

    -- Render posts list
    match "posts.html" $ route idRoute
    _ <- ($)
        create "posts.html" $ constA mempty
            >>> arr (setField "blogTitle" blogTitle)
            >>> arr (setField "title" blogTitle)
            >>> requireAllA "posts/*" addPostList
            >>> applyTemplateCompiler "templates/posts.html"
            >>> applyTemplateCompiler "templates/default.html"
            >>> relativizeUrlsCompiler

    -- Index
    match "index.html" $ route idRoute
    _ <- ($)
        create "index.html" $ constA mempty
            >>> arr (setField "blogTitle" blogTitle)
            >>> arr (setField "title" blogTitle)
            >>> requireA "tags" (setFieldA "tagcloud" renderTagCloud')
            >>> requireAllA "posts/*" (id *** arr (take 3 . reverse . chronological) >>> addPostList)
            >>> applyTemplateCompiler "templates/index.html"
            >>> applyTemplateCompiler "templates/default.html"
            >>> relativizeUrlsCompiler

    -- Tags
    _ <- ($)
        create "tags" $
            requireAll "posts/*" (\_ ps -> readTags ps :: Tags String)

    -- Add a tag list compiler for every tag
    match "tags/*" $ route $ setExtension ".html"
    metaCompile $ require_ "tags"
        >>> arr tagsMap
        >>> arr (map (\(t, p) -> (tagIdentifier t, makeTagList t p)))


    -- Read templates
    _ <- ($)
        match "templates/*" $ compile templateCompiler

    -- Render RSS feed
    match "rss.xml" $ route idRoute
    create "rss.xml" $
        requireAll_ "posts/*"
            >>> mapCompiler (arr $ copyBodyToField "description")
            >>> renderRss feedConfiguration
  where
    renderTagCloud' :: Compiler (Tags String) String
    renderTagCloud' = renderTagCloud tagIdentifier 100 120

    tagIdentifier :: String -> Identifier (Page String)
    tagIdentifier = fromCapture "tags/*"

-- | Auxiliary compiler: generate a post list from a list of given posts, and
-- add it to the current page under @$posts@
--
addPostList :: Compiler (Page String, [Page String]) (Page String)
addPostList = setFieldA "posts" $
    arr (reverse . chronological)
        >>> require "templates/position.html" (\p t -> map (applyTemplate t) p)
        >>> arr mconcat
        >>> arr pageBody
config :: HakyllConfiguration
config = defaultHakyllConfiguration { deployCommand = deploy }
  where deploy = "make deploy && make clean"

makeTagList :: String
            -> [Page String]
            -> Compiler () (Page String)
makeTagList tag posts =
    constA (mempty, posts)
        >>> addPostList
        >>> arr (setField "title" ("Posts tagged &#8216;" ++ tag ++ "&#8217;"))
        >>> arr (setField "blogTitle" blogTitle)
        >>> applyTemplateCompiler "templates/posts.html"
        >>> applyTemplateCompiler "templates/default.html"
        >>> relativizeUrlsCompiler

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
    { feedTitle       = blogTitle
    , feedDescription = "机上日記のRSSフィード"
    , feedAuthorName  = "dekokun"
    , feedRoot  = "http://dekokun.github.com"
    , feedAuthorEmail = "shintaro.kurachi@gmail.com"
    }

blogTitle :: String
blogTitle = "机上日記"
