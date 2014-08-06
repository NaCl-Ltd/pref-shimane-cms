--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: access_counts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_counts (
    id integer DEFAULT nextval(('public.access_counts_id_seq'::text)::regclass) NOT NULL,
    datetime timestamp without time zone,
    genre_id integer,
    page_id integer,
    section_id integer,
    path text,
    count integer,
    count_inside integer
);


--
-- Name: access_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE access_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE access_counts_id_seq OWNED BY access_counts.id;


--
-- Name: action_masters; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE action_masters (
    id integer DEFAULT nextval(('public.action_masters_id_seq'::text)::regclass) NOT NULL,
    name character varying(255)
);


--
-- Name: action_masters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE action_masters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: action_masters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE action_masters_id_seq OWNED BY action_masters.id;


--
-- Name: advertisement_lists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE advertisement_lists (
    id integer DEFAULT nextval(('public.advertisement_lists_id_seq'::text)::regclass) NOT NULL,
    advertisement_id integer,
    state integer,
    pref_ad_number integer,
    corp_ad_number integer
);


--
-- Name: advertisement_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE advertisement_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: advertisement_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE advertisement_lists_id_seq OWNED BY advertisement_lists.id;


--
-- Name: advertisements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE advertisements (
    id integer DEFAULT nextval(('public.advertisements_id_seq'::text)::regclass) NOT NULL,
    name character varying(255),
    advertiser character varying(255),
    image character varying(255),
    alt character varying(255),
    url text,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    side_type integer,
    show_in_header boolean,
    corp_ad_number integer,
    pref_ad_number integer,
    state integer DEFAULT 1,
    description character varying(255),
    description_link text
);


--
-- Name: advertisements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE advertisements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: advertisements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE advertisements_id_seq OWNED BY advertisements.id;


--
-- Name: board_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE board_comments (
    id integer DEFAULT nextval(('public.board_comments_id_seq'::text)::regclass) NOT NULL,
    board_id integer NOT NULL,
    body text NOT NULL,
    "from" character varying(255) NOT NULL,
    public boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_addr character varying(255)
);


--
-- Name: board_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE board_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: board_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE board_comments_id_seq OWNED BY board_comments.id;


--
-- Name: boards; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE boards (
    id integer DEFAULT nextval(('public.boards_id_seq'::text)::regclass) NOT NULL,
    title character varying(255) NOT NULL,
    section_id integer NOT NULL
);


--
-- Name: boards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE boards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE boards_id_seq OWNED BY boards.id;


--
-- Name: cms_actions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cms_actions (
    id integer DEFAULT nextval(('public.cms_actions_id_seq'::text)::regclass) NOT NULL,
    action_master_id integer,
    controller_name character varying(255),
    action_name character varying(255)
);


--
-- Name: cms_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cms_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cms_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cms_actions_id_seq OWNED BY cms_actions.id;


--
-- Name: divisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE divisions (
    id integer DEFAULT nextval(('public.divisions_id_seq'::text)::regclass) NOT NULL,
    name character varying(255),
    number integer,
    enable boolean
);


--
-- Name: divisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE divisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: divisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE divisions_id_seq OWNED BY divisions.id;


--
-- Name: emergency_infos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE emergency_infos (
    id integer DEFAULT nextval(('public.emergency_infos_id_seq'::text)::regclass) NOT NULL,
    display_start_datetime timestamp without time zone NOT NULL,
    display_end_datetime timestamp without time zone NOT NULL,
    content text NOT NULL
);


--
-- Name: emergency_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emergency_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emergency_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE emergency_infos_id_seq OWNED BY emergency_infos.id;


--
-- Name: enquete_answer_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE enquete_answer_items (
    id integer DEFAULT nextval(('public.enquete_answer_items_id_seq'::text)::regclass) NOT NULL,
    answer_id integer NOT NULL,
    enquete_item_id integer NOT NULL,
    value text,
    other text
);


--
-- Name: enquete_answer_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enquete_answer_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enquete_answer_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enquete_answer_items_id_seq OWNED BY enquete_answer_items.id;


--
-- Name: enquete_answers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE enquete_answers (
    id integer DEFAULT nextval(('public.enquete_answers_id_seq'::text)::regclass) NOT NULL,
    page_id integer NOT NULL,
    answered_at timestamp without time zone NOT NULL,
    remote_addr character varying(255) NOT NULL
);


--
-- Name: enquete_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enquete_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enquete_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enquete_answers_id_seq OWNED BY enquete_answers.id;


--
-- Name: enquete_item_values; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE enquete_item_values (
    id integer DEFAULT nextval(('public.enquete_item_values_id_seq'::text)::regclass) NOT NULL,
    value text,
    enquete_item_id integer,
    other boolean
);


--
-- Name: enquete_item_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enquete_item_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enquete_item_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enquete_item_values_id_seq OWNED BY enquete_item_values.id;


--
-- Name: enquete_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE enquete_items (
    id integer DEFAULT nextval(('public.enquete_items_id_seq'::text)::regclass) NOT NULL,
    page_id integer NOT NULL,
    no integer,
    name character varying(255),
    form_type character varying(255)
);


--
-- Name: enquete_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enquete_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enquete_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enquete_items_id_seq OWNED BY enquete_items.id;


SET default_with_oids = false;

--
-- Name: event_referers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE event_referers (
    id integer NOT NULL,
    plugin integer,
    path character varying(255),
    target_path character varying(255)
);


--
-- Name: event_referers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_referers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_referers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_referers_id_seq OWNED BY event_referers.id;


SET default_with_oids = true;

--
-- Name: genres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE genres (
    id integer DEFAULT nextval(('public.genres_id_seq'::text)::regclass) NOT NULL,
    parent_id integer,
    name character varying(255),
    title character varying(255),
    path character varying(255),
    description text,
    original_id integer,
    no integer,
    uri text,
    section_id integer,
    tracking_code text,
    auth boolean
);


--
-- Name: genres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE genres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE genres_id_seq OWNED BY genres.id;


--
-- Name: help_actions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE help_actions (
    id integer DEFAULT nextval(('public.help_actions_id_seq'::text)::regclass) NOT NULL,
    name character varying(255),
    action_master_id integer,
    help_category_id integer
);


--
-- Name: help_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE help_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: help_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE help_actions_id_seq OWNED BY help_actions.id;


--
-- Name: help_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE help_categories (
    id integer DEFAULT nextval(('public.help_categories_id_seq'::text)::regclass) NOT NULL,
    name character varying(255),
    parent_id integer,
    number integer,
    navigation boolean
);


--
-- Name: help_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE help_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: help_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE help_categories_id_seq OWNED BY help_categories.id;


--
-- Name: help_contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE help_contents (
    id integer DEFAULT nextval(('public.help_contents_id_seq'::text)::regclass) NOT NULL,
    content text
);


--
-- Name: help_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE help_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: help_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE help_contents_id_seq OWNED BY help_contents.id;


--
-- Name: helps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE helps (
    id integer DEFAULT nextval(('public.helps_id_seq'::text)::regclass) NOT NULL,
    name character varying(255),
    public integer,
    help_category_id integer,
    help_content_id integer,
    number integer
);


--
-- Name: helps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE helps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: helps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE helps_id_seq OWNED BY helps.id;


--
-- Name: infos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE infos (
    id integer DEFAULT nextval(('public.infos_id_seq'::text)::regclass) NOT NULL,
    title character varying(255),
    last_modified timestamp without time zone,
    content text
);


--
-- Name: infos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE infos_id_seq OWNED BY infos.id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE jobs (
    id integer DEFAULT nextval(('public.jobs_id_seq'::text)::regclass) NOT NULL,
    datetime timestamp without time zone,
    action character varying(255),
    arg1 character varying(255),
    arg2 character varying(255)
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- Name: lost_links; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lost_links (
    id integer DEFAULT nextval(('public.lost_links_id_seq'::text)::regclass) NOT NULL,
    page_id integer,
    section_id integer,
    side_type integer,
    target text,
    message text
);


--
-- Name: lost_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lost_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lost_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lost_links_id_seq OWNED BY lost_links.id;


--
-- Name: mailmagazine_contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mailmagazine_contents (
    id integer DEFAULT nextval(('public.mailmagazine_contents_id_seq'::text)::regclass) NOT NULL,
    section_id integer,
    mailmagazine_id integer,
    title character varying(255),
    content text,
    datetime timestamp without time zone,
    send_mailmagazine_id integer,
    no integer
);


--
-- Name: mailmagazine_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mailmagazine_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mailmagazine_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mailmagazine_contents_id_seq OWNED BY mailmagazine_contents.id;


--
-- Name: mailmagazines; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mailmagazines (
    id integer DEFAULT nextval(('public.mailmagazines_id_seq'::text)::regclass) NOT NULL,
    section_id integer,
    mail_address character varying(255),
    header text,
    footer text
);


--
-- Name: mailmagazines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mailmagazines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mailmagazines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mailmagazines_id_seq OWNED BY mailmagazines.id;


--
-- Name: news; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE news (
    id integer DEFAULT nextval(('public.news_id_seq'::text)::regclass) NOT NULL,
    page_id integer,
    published_at timestamp without time zone NOT NULL,
    title character varying(255) NOT NULL
);


--
-- Name: news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE news_id_seq OWNED BY news.id;


--
-- Name: page_contents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE page_contents (
    id integer DEFAULT nextval(('public.page_contents_id_seq'::text)::regclass) NOT NULL,
    page_id integer,
    content text,
    begin_date timestamp without time zone,
    end_date timestamp without time zone,
    last_modified timestamp without time zone,
    mobile text,
    news_title character varying(255),
    user_name character varying(255),
    tel character varying(255),
    email character varying(255),
    comment text,
    admission integer DEFAULT 0,
    top_news integer DEFAULT 0,
    section_news integer DEFAULT 0,
    begin_event_date date,
    end_event_date date
);


--
-- Name: page_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE page_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE page_contents_id_seq OWNED BY page_contents.id;


--
-- Name: page_links; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE page_links (
    id integer DEFAULT nextval(('public.page_links_id_seq'::text)::regclass) NOT NULL,
    page_content_id integer,
    link text
);


--
-- Name: page_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE page_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE page_links_id_seq OWNED BY page_links.id;


--
-- Name: page_locks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE page_locks (
    id integer DEFAULT nextval(('public.page_locks_id_seq'::text)::regclass) NOT NULL,
    page_id integer,
    status integer,
    user_id integer,
    "time" timestamp without time zone,
    session_id character varying(255)
);


--
-- Name: page_locks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE page_locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE page_locks_id_seq OWNED BY page_locks.id;


--
-- Name: page_revisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE page_revisions (
    id integer DEFAULT nextval(('public.page_revisions_id_seq'::text)::regclass) NOT NULL,
    page_id integer,
    user_id integer,
    last_modified timestamp without time zone,
    user_name character varying(255),
    tel character varying(255),
    email character varying(255),
    comment text
);


--
-- Name: page_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE page_revisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE page_revisions_id_seq OWNED BY page_revisions.id;


--
-- Name: pages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pages (
    id integer DEFAULT nextval(('public.pages_id_seq'::text)::regclass) NOT NULL,
    genre_id integer,
    name character varying(255),
    title character varying(255)
);


--
-- Name: pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pages_id_seq OWNED BY pages.id;


--
-- Name: schema_info; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_info (
    version integer
);


--
-- Name: section_news; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE section_news (
    id integer DEFAULT nextval(('public.section_news_id_seq'::text)::regclass) NOT NULL,
    page_id integer,
    begin_date timestamp without time zone,
    path character varying(255),
    title character varying(255),
    genre_id integer
);


--
-- Name: section_news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE section_news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: section_news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE section_news_id_seq OWNED BY section_news.id;


--
-- Name: sections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sections (
    id integer DEFAULT nextval(('public.sections_id_seq'::text)::regclass) NOT NULL,
    code character varying(255),
    name character varying(255),
    place_code integer,
    info text,
    top_genre_id integer,
    number integer,
    link character varying(255),
    division_id integer,
    ftp character varying(255)
);


--
-- Name: sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sections_id_seq OWNED BY sections.id;


--
-- Name: sent_mailmagazines; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sent_mailmagazines (
    id integer DEFAULT nextval(('public.sent_mailmagazines_id_seq'::text)::regclass) NOT NULL,
    datetime timestamp without time zone,
    mailmagazine_id integer,
    title character varying(255),
    content text
);


--
-- Name: sent_mailmagazines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sent_mailmagazines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sent_mailmagazines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sent_mailmagazines_id_seq OWNED BY sent_mailmagazines.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id integer DEFAULT nextval(('public.sessions_id_seq'::text)::regclass) NOT NULL,
    session_id character varying(255),
    data text,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: site_components; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE site_components (
    id integer DEFAULT nextval(('public.site_components_id_seq'::text)::regclass) NOT NULL,
    name character varying(255),
    value text
);


--
-- Name: site_components_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE site_components_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: site_components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE site_components_id_seq OWNED BY site_components.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer DEFAULT nextval(('public.users_id_seq'::text)::regclass) NOT NULL,
    name character varying(255),
    section_id integer,
    login character varying(255),
    password character varying(255),
    authority integer,
    mail character varying(255)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: web_monitors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE web_monitors (
    id integer DEFAULT nextval(('public.web_monitors_id_seq'::text)::regclass) NOT NULL,
    name character varying(255),
    login character varying(255),
    password character varying(255),
    genre_id integer,
    state integer DEFAULT 0
);


--
-- Name: web_monitors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE web_monitors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_monitors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE web_monitors_id_seq OWNED BY web_monitors.id;


--
-- Name: words; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE words (
    id integer DEFAULT nextval(('public.words_id_seq'::text)::regclass) NOT NULL,
    base character varying(255),
    text character varying(255),
    updated_at timestamp without time zone NOT NULL,
    user_id integer
);


--
-- Name: words_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE words_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: words_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE words_id_seq OWNED BY words.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_referers ALTER COLUMN id SET DEFAULT nextval('event_referers_id_seq'::regclass);


--
-- Name: access_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_counts
    ADD CONSTRAINT access_counts_pkey PRIMARY KEY (id);


--
-- Name: action_masters_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY action_masters
    ADD CONSTRAINT action_masters_pkey PRIMARY KEY (id);


--
-- Name: advertisement_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY advertisement_lists
    ADD CONSTRAINT advertisement_lists_pkey PRIMARY KEY (id);


--
-- Name: advertisements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY advertisements
    ADD CONSTRAINT advertisements_pkey PRIMARY KEY (id);


--
-- Name: board_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY board_comments
    ADD CONSTRAINT board_comments_pkey PRIMARY KEY (id);


--
-- Name: boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);


--
-- Name: cms_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cms_actions
    ADD CONSTRAINT cms_actions_pkey PRIMARY KEY (id);


--
-- Name: divisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY divisions
    ADD CONSTRAINT divisions_pkey PRIMARY KEY (id);


--
-- Name: emergency_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY emergency_infos
    ADD CONSTRAINT emergency_infos_pkey PRIMARY KEY (id);


--
-- Name: enquete_answer_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY enquete_answer_items
    ADD CONSTRAINT enquete_answer_items_pkey PRIMARY KEY (id);


--
-- Name: enquete_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY enquete_answers
    ADD CONSTRAINT enquete_answers_pkey PRIMARY KEY (id);


--
-- Name: enquete_item_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY enquete_item_values
    ADD CONSTRAINT enquete_item_values_pkey PRIMARY KEY (id);


--
-- Name: enquete_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY enquete_items
    ADD CONSTRAINT enquete_items_pkey PRIMARY KEY (id);


--
-- Name: event_referers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY event_referers
    ADD CONSTRAINT event_referers_pkey PRIMARY KEY (id);


--
-- Name: genres_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (id);


--
-- Name: help_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY help_actions
    ADD CONSTRAINT help_actions_pkey PRIMARY KEY (id);


--
-- Name: help_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY help_categories
    ADD CONSTRAINT help_categories_pkey PRIMARY KEY (id);


--
-- Name: help_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY help_contents
    ADD CONSTRAINT help_contents_pkey PRIMARY KEY (id);


--
-- Name: helps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY helps
    ADD CONSTRAINT helps_pkey PRIMARY KEY (id);


--
-- Name: infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY infos
    ADD CONSTRAINT infos_pkey PRIMARY KEY (id);


--
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: lost_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lost_links
    ADD CONSTRAINT lost_links_pkey PRIMARY KEY (id);


--
-- Name: mailmagazine_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mailmagazine_contents
    ADD CONSTRAINT mailmagazine_contents_pkey PRIMARY KEY (id);


--
-- Name: mailmagazines_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mailmagazines
    ADD CONSTRAINT mailmagazines_pkey PRIMARY KEY (id);


--
-- Name: news_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_pkey PRIMARY KEY (id);


--
-- Name: page_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY page_contents
    ADD CONSTRAINT page_contents_pkey PRIMARY KEY (id);


--
-- Name: page_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY page_links
    ADD CONSTRAINT page_links_pkey PRIMARY KEY (id);


--
-- Name: page_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY page_locks
    ADD CONSTRAINT page_locks_pkey PRIMARY KEY (id);


--
-- Name: page_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY page_revisions
    ADD CONSTRAINT page_revisions_pkey PRIMARY KEY (id);


--
-- Name: pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: section_news_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY section_news
    ADD CONSTRAINT section_news_pkey PRIMARY KEY (id);


--
-- Name: sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: sent_mailmagazines_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sent_mailmagazines
    ADD CONSTRAINT sent_mailmagazines_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: site_components_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY site_components
    ADD CONSTRAINT site_components_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: web_monitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY web_monitors
    ADD CONSTRAINT web_monitors_pkey PRIMARY KEY (id);


--
-- Name: words_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY words
    ADD CONSTRAINT words_pkey PRIMARY KEY (id);


--
-- Name: access_counts_datetime_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX access_counts_datetime_index ON access_counts USING btree (datetime);


--
-- Name: access_counts_path_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX access_counts_path_index ON access_counts USING btree (path);


--
-- Name: genres_parent_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX genres_parent_id_index ON genres USING btree (parent_id);


--
-- Name: genres_path_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX genres_path_index ON genres USING btree (path);


--
-- Name: genres_section_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX genres_section_id_index ON genres USING btree (section_id);


--
-- Name: jobs_action_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX jobs_action_index ON jobs USING btree (action);


--
-- Name: jobs_arg1_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX jobs_arg1_index ON jobs USING btree (arg1);


--
-- Name: page_contents_page_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX page_contents_page_id_index ON page_contents USING btree (page_id);


--
-- Name: page_links_link_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX page_links_link_index ON page_links USING btree (link);


--
-- Name: pages_genre_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX pages_genre_id_index ON pages USING btree (genre_id);


--
-- Name: sessions_session_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX sessions_session_id_index ON sessions USING btree (session_id);


--
-- Name: words_text_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX words_text_index ON words USING btree (text);


--
-- PostgreSQL database dump complete
--

