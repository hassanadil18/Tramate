--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: api_credentials; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.api_credentials (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    platform character varying,
    api_key character varying,
    api_secret character varying,
    ip_restriction character varying,
    label character varying,
    active boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.api_credentials OWNER TO mujeeb;

--
-- Name: api_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.api_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_credentials_id_seq OWNER TO mujeeb;

--
-- Name: api_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.api_credentials_id_seq OWNED BY public.api_credentials.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO mujeeb;

--
-- Name: channels; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.channels (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    price_per_month numeric(10,2),
    discord_channel_id character varying NOT NULL,
    tramate_resell_enabled boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    status character varying DEFAULT 'active'::character varying,
    channel_type character varying DEFAULT 'discord'::character varying,
    logo_url character varying,
    signal_format character varying DEFAULT 'standard'::character varying,
    signal_template text,
    webhook_url character varying,
    api_key character varying
);


ALTER TABLE public.channels OWNER TO mujeeb;

--
-- Name: channels_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.channels_id_seq OWNER TO mujeeb;

--
-- Name: channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.channels_id_seq OWNED BY public.channels.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    message text NOT NULL,
    read boolean DEFAULT false,
    notification_type character varying,
    read_at timestamp(6) without time zone,
    data json,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.notifications OWNER TO mujeeb;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO mujeeb;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.payments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    amount numeric(10,2) NOT NULL,
    payment_gateway_id character varying NOT NULL,
    status character varying NOT NULL,
    status_updated_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    notes text
);


ALTER TABLE public.payments OWNER TO mujeeb;

--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_id_seq OWNER TO mujeeb;

--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO mujeeb;

--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.subscriptions (
    id bigint NOT NULL,
    name character varying,
    price numeric(10,2) DEFAULT 0.0,
    description text,
    trade_limit integer,
    user_id bigint,
    status character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.subscriptions OWNER TO mujeeb;

--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriptions_id_seq OWNER TO mujeeb;

--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: system_logs; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.system_logs (
    id bigint NOT NULL,
    level character varying NOT NULL,
    message text NOT NULL,
    context jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    source character varying
);


ALTER TABLE public.system_logs OWNER TO mujeeb;

--
-- Name: system_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.system_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_logs_id_seq OWNER TO mujeeb;

--
-- Name: system_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.system_logs_id_seq OWNED BY public.system_logs.id;


--
-- Name: trade_signals; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.trade_signals (
    id bigint NOT NULL,
    channel_id bigint NOT NULL,
    message_content text NOT NULL,
    parsed_data json,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.trade_signals OWNER TO mujeeb;

--
-- Name: trade_signals_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.trade_signals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trade_signals_id_seq OWNER TO mujeeb;

--
-- Name: trade_signals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.trade_signals_id_seq OWNED BY public.trade_signals.id;


--
-- Name: trades; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.trades (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    trade_signal_id bigint NOT NULL,
    binance_trade_id character varying,
    status character varying NOT NULL,
    amount numeric(15,8),
    "timestamp" timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    pre_trade_data json,
    post_trade_data json,
    error_data json,
    take_profit_data json,
    stop_loss_data json,
    needs_review boolean,
    review_reason character varying,
    review_requested_at timestamp(6) without time zone
);


ALTER TABLE public.trades OWNER TO mujeeb;

--
-- Name: trades_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.trades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trades_id_seq OWNER TO mujeeb;

--
-- Name: trades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.trades_id_seq OWNED BY public.trades.id;


--
-- Name: user_channel_accesses; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.user_channel_accesses (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    channel_id bigint NOT NULL,
    access_type character varying NOT NULL,
    payment_id bigint,
    access_start_date timestamp(6) without time zone NOT NULL,
    access_end_date timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.user_channel_accesses OWNER TO mujeeb;

--
-- Name: user_channel_accesses_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.user_channel_accesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_channel_accesses_id_seq OWNER TO mujeeb;

--
-- Name: user_channel_accesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.user_channel_accesses_id_seq OWNED BY public.user_channel_accesses.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: mujeeb
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying NOT NULL,
    password_digest character varying NOT NULL,
    discord_id character varying,
    binance_api_key character varying,
    encrypted_binance_api_secret character varying,
    binance_api_secret_iv character varying,
    subscription_status character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    full_name character varying,
    admin boolean DEFAULT false,
    subscription_id integer,
    trades_count integer,
    subscription_start_date timestamp(6) without time zone,
    subscription_end_date timestamp(6) without time zone
);


ALTER TABLE public.users OWNER TO mujeeb;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: mujeeb
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO mujeeb;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mujeeb
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: api_credentials id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.api_credentials ALTER COLUMN id SET DEFAULT nextval('public.api_credentials_id_seq'::regclass);


--
-- Name: channels id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.channels ALTER COLUMN id SET DEFAULT nextval('public.channels_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: system_logs id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.system_logs ALTER COLUMN id SET DEFAULT nextval('public.system_logs_id_seq'::regclass);


--
-- Name: trade_signals id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.trade_signals ALTER COLUMN id SET DEFAULT nextval('public.trade_signals_id_seq'::regclass);


--
-- Name: trades id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.trades ALTER COLUMN id SET DEFAULT nextval('public.trades_id_seq'::regclass);


--
-- Name: user_channel_accesses id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.user_channel_accesses ALTER COLUMN id SET DEFAULT nextval('public.user_channel_accesses_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: api_credentials; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.api_credentials (id, user_id, platform, api_key, api_secret, ip_restriction, label, active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
environment	development	2025-05-22 13:31:23.941221	2025-05-22 13:31:23.941226
schema_sha1	7562d9a7b89633681f9617143b7f6796063bb7cc	2025-05-22 13:31:23.95165	2025-05-22 13:31:23.95166
\.


--
-- Data for Name: channels; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.channels (id, name, description, price_per_month, discord_channel_id, tramate_resell_enabled, created_at, updated_at, status, channel_type, logo_url, signal_format, signal_template, webhook_url, api_key) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.notifications (id, user_id, message, read, notification_type, read_at, data, created_at, updated_at) FROM stdin;
1	1	Welcome to Tramate Admin Dashboard!	f	system	\N	{"welcome":true}	2025-05-23 14:47:58.500277	2025-05-23 14:47:58.500277
2	1	New user registration: John Doe	f	user	\N	{"user_id":1}	2025-05-23 14:47:58.509224	2025-05-23 14:47:58.509224
3	1	New payment received: $99.99	f	payment	\N	{"payment_id":1,"amount":99.99}	2025-05-23 14:47:58.514141	2025-05-23 14:47:58.514141
4	1	New channel created: Crypto Signals	f	channel	\N	{"channel_id":1}	2025-05-23 14:47:58.518348	2025-05-23 14:47:58.518348
5	1	System update scheduled for tomorrow	f	system	\N	{"maintenance":true,"scheduled_at":"2025-05-24T14:47:58.522Z"}	2025-05-23 14:47:58.522727	2025-05-23 14:47:58.522727
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.payments (id, user_id, amount, payment_gateway_id, status, status_updated_at, created_at, updated_at, notes) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.schema_migrations (version) FROM stdin;
20250516151324
20250516151323
20250516133351
20250513182440
20250513180327
20250429000001
20250522133905
20250522195145
20250522195256
20250523120755
20250523131721
20250523132356
20250523133047
20250523134118
20250523142735
\.


--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.subscriptions (id, name, price, description, trade_limit, user_id, status, created_at, updated_at) FROM stdin;
1	Starter	0.00	Start with basic trading, limited to 1 trade per day	1	\N	\N	2025-05-22 19:55:46.348838	2025-05-22 19:55:46.348838
2	Intermediate	5.00	Step up your trading with up to 20 trades	20	\N	\N	2025-05-22 19:55:46.357469	2025-05-22 19:55:46.357469
3	Premium	15.00	Unlimited trading for serious traders	\N	\N	\N	2025-05-22 19:55:46.369368	2025-05-22 19:55:46.369368
\.


--
-- Data for Name: system_logs; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.system_logs (id, level, message, context, created_at, updated_at, source) FROM stdin;
1	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 13:32:35.346891	2025-05-22 13:32:35.346891	\N
2	info	Request completed: GET /auth/login	{"ip": "127.0.0.1", "action": "login", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 13:33:37.880977	2025-05-22 13:33:37.880977	\N
3	info	Request completed: POST /auth/authenticate	{"ip": "127.0.0.1", "action": "authenticate", "params": {"email": "admin@example.com", "commit": "Log In", "remember_me": "0", "authenticity_token": "VOnfpfRxUEFVpbyOq089D-211hyryMLCG_Hy-jX8xnRyGjwKln5sJ-UEkdGdakHHlhEhC5lMU2HQqz-hDlU_xw"}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 13:36:22.734883	2025-05-22 13:36:22.734883	\N
4	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:02:28.170838	2025-05-22 14:02:28.170838	\N
5	info	Request completed: GET /auth/login	{"ip": "127.0.0.1", "action": "login", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:02:36.965393	2025-05-22 14:02:36.965393	\N
6	info	Request completed: POST /auth/authenticate	{"ip": "127.0.0.1", "action": "authenticate", "params": {"email": "admin@example.com", "commit": "Log In", "remember_me": "0", "authenticity_token": "qcYBlIULXaZWYBjrqZVsoyeGyg54xHN8Se119184_NWPNeI75wRhwObBNbSfsBBrXCI9GUpA4t-Ct7isZJEFZg"}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:04:51.506871	2025-05-22 14:04:51.506871	\N
7	info	Request completed: POST /auth/authenticate	{"ip": "127.0.0.1", "action": "authenticate", "params": {"email": "admin@example.com", "commit": "Log In", "remember_me": "0", "authenticity_token": "3SD0xovkeVlknn4OP_a068onnsiIS9qgXkzEU_wutuX70xdp6etFP9Q_U1EJ08gjsYNp37rPSwOVFgkIx4dPVg"}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:08:00.986257	2025-05-22 14:08:00.986257	\N
8	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:15:00.406901	2025-05-22 14:15:00.406901	\N
9	info	Request completed: GET /auth/login	{"ip": "127.0.0.1", "action": "login", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:16:14.15481	2025-05-22 14:16:14.15481	\N
10	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:17:52.43729	2025-05-22 14:17:52.43729	\N
11	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:18:20.108761	2025-05-22 14:18:20.108761	\N
12	info	Request completed: GET /auth/login	{"ip": "127.0.0.1", "action": "login", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:19:57.812194	2025-05-22 14:19:57.812194	\N
13	info	Request completed: POST /auth/authenticate	{"ip": "127.0.0.1", "action": "authenticate", "params": {"email": "admin@example.com", "commit": "Log In", "remember_me": "0", "authenticity_token": "R85mLRD5HlxEvdY_0XXk9rkys-qsrUW4fbdEfkhGIR2_H0IN80uOeV-AVh8oBdHAFkq5RMZLaVeaieXd7Vw2sQ"}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 14:49:13.735762	2025-05-22 14:49:13.735762	\N
14	info	Request completed: POST /auth/authenticate	{"ip": "127.0.0.1", "action": "authenticate", "params": {"email": "admin@example.com", "commit": "Log In", "remember_me": "0", "authenticity_token": "R85mLRD5HlxEvdY_0XXk9rkys-qsrUW4fbdEfkhGIR2_H0IN80uOeV-AVh8oBdHAFkq5RMZLaVeaieXd7Vw2sQ"}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 15:00:42.252141	2025-05-22 15:00:42.252141	\N
15	info	Request completed: POST /auth/authenticate	{"ip": "127.0.0.1", "action": "authenticate", "params": {"email": "admin@example.com", "commit": "Log In", "remember_me": "0", "authenticity_token": "GSSQN2yJmP0MoaBjde47cszcs-7_rFj2_TGf7gz0tGXh9bQXjzsI2BecIEOMng5EY6S5QJVKdBkaDz5Nqe6jyQ"}, "user_id": 1, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 15:03:53.449462	2025-05-22 15:03:53.449462	\N
16	info	Request completed: GET /dashboard	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 15:18:54.283731	2025-05-22 15:18:54.283731	\N
17	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 20:30:21.807346	2025-05-22 20:30:21.807346	\N
18	info	Request completed: GET /auth/register	{"ip": "127.0.0.1", "action": "register", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:135.0) Gecko/20100101 Firefox/135.0"}	2025-05-22 20:30:57.497651	2025-05-22 20:30:57.497651	\N
19	info	Request completed: GET /	\N	2025-05-23 12:09:20.380776	2025-05-23 12:09:20.380776	{:controller=>"home", :action=>"index", :params=>#<ActionController::Parameters {} permitted: false>, :user_id=>nil, :ip=>"127.0.0.1", :user_agent=>"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}
20	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:16:16.553183	2025-05-23 12:16:16.553183	home#index
21	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:20:05.734302	2025-05-23 12:20:05.734302	home#index
22	info	Request completed: GET /auth/login	{"ip": "127.0.0.1", "action": "login_form", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:23:44.303898	2025-05-23 12:23:44.303898	auth#login_form
23	info	Request completed: POST /auth/login	{"ip": "127.0.0.1", "action": "login", "params": {"email": "admin@example.com", "commit": "Log In", "authenticity_token": "RvYb7OMdke7JeokLSzZPoUNa6DNRrFMxvtZiW_dO3ectvxB8XEc1Iq6fOucQqUYv4noGl9vyDVpVY9-JQapZ5A"}, "user_id": 1, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:25:15.998639	2025-05-23 12:25:15.998639	auth#login
24	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:25:16.132098	2025-05-23 12:25:16.132098	dashboard#index
25	info	Request completed: GET /admin/subscriptions	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:25:27.91024	2025-05-23 12:25:27.91024	subscriptions#index
26	info	Request completed: GET /admin/subscriptions	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:25:47.694049	2025-05-23 12:25:47.694049	subscriptions#index
27	info	Request completed: GET /admin/dashboard	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:27:28.114796	2025-05-23 12:27:28.114796	dashboard#index
28	info	Request completed: GET /auth/login	{"ip": "127.0.0.1", "action": "login_form", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:31:35.609568	2025-05-23 12:31:35.609568	auth#login_form
29	info	Request completed: GET /admin/subscriptions	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:32:02.173295	2025-05-23 12:32:02.173295	subscriptions#index
30	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:35:00.168843	2025-05-23 12:35:00.168843	home#index
31	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:35:00.349263	2025-05-23 12:35:00.349263	dashboard#index
32	info	Request completed: GET /admin/subscriptions	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:35:19.058672	2025-05-23 12:35:19.058672	subscriptions#index
33	info	Request completed: GET /admin/trades	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "trades", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:35:28.612399	2025-05-23 12:35:28.612399	trades#index
34	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:39:00.930577	2025-05-23 12:39:00.930577	home#index
35	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:39:01.150082	2025-05-23 12:39:01.150082	dashboard#index
36	info	Request completed: GET /admin/subscriptions	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:39:15.521465	2025-05-23 12:39:15.521465	subscriptions#index
37	info	Request completed: GET /admin/trades	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "trades", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:39:23.801539	2025-05-23 12:39:23.801539	trades#index
38	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:43:22.097066	2025-05-23 12:43:22.097066	home#index
39	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:43:22.275742	2025-05-23 12:43:22.275742	dashboard#index
40	info	Request completed: GET /admin/users	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "users", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:43:26.621244	2025-05-23 12:43:26.621244	users#index
41	info	Request completed: GET /admin/users	{"ip": "127.0.0.1", "action": "index", "params": {"admin": "", "email": "", "commit": "Apply Filters"}, "user_id": 1, "controller": "users", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:43:47.88171	2025-05-23 12:43:47.88171	users#index
42	info	Request completed: GET /admin/users	{"ip": "127.0.0.1", "action": "index", "params": {"admin": "false", "email": "", "commit": "Apply Filters"}, "user_id": 1, "controller": "users", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:43:53.012555	2025-05-23 12:43:53.012555	users#index
43	info	Request completed: GET /auth/login	{"ip": "127.0.0.1", "action": "login_form", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 12:47:37.979794	2025-05-23 12:47:37.979794	auth#login_form
44	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:03:44.860717	2025-05-23 13:03:44.860717	home#index
45	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:03:44.983535	2025-05-23 13:03:44.983535	dashboard#index
46	info	Request completed: GET /admin/users	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "users", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:03:48.929184	2025-05-23 13:03:48.929184	users#index
47	info	Request completed: GET /admin/users.csv	{"ip": "127.0.0.1", "action": "index", "params": {"format": "csv"}, "user_id": 1, "controller": "users", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:03:52.270749	2025-05-23 13:03:52.270749	users#index
48	info	Request completed: GET /admin/subscriptions	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:04:06.148711	2025-05-23 13:04:06.148711	subscriptions#index
49	info	Request completed: GET /admin/subscriptions	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:04:09.857731	2025-05-23 13:04:09.857731	subscriptions#index
50	info	Request completed: GET /admin/subscriptions	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:12:43.573301	2025-05-23 13:12:43.573301	subscriptions#index
51	info	Request completed: GET /admin/subscriptions/1	{"ip": "127.0.0.1", "action": "show", "params": {"id": "1"}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:12:48.079742	2025-05-23 13:12:48.079742	subscriptions#show
52	info	Request completed: GET /admin/subscriptions/1/edit	{"ip": "127.0.0.1", "action": "edit", "params": {"id": "1"}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:12:58.151292	2025-05-23 13:12:58.151292	subscriptions#edit
53	info	Request completed: GET /admin/subscriptions/new	{"ip": "127.0.0.1", "action": "new", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:13:08.223323	2025-05-23 13:13:08.223323	subscriptions#new
54	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:21:49.163549	2025-05-23 13:21:49.163549	home#index
55	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:21:49.443669	2025-05-23 13:21:49.443669	dashboard#index
56	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:28:26.972951	2025-05-23 13:28:26.972951	home#index
57	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:28:27.099509	2025-05-23 13:28:27.099509	dashboard#index
58	info	Request completed: GET /admin/channels	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "channels", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:28:29.768011	2025-05-23 13:28:29.768011	channels#index
59	info	Request completed: GET /admin/trades	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "trades", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:29:26.247628	2025-05-23 13:29:26.247628	trades#index
60	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:36:00.550194	2025-05-23 13:36:00.550194	dashboard#index
61	info	Request completed: GET /admin/channels	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "channels", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:36:03.274071	2025-05-23 13:36:03.274071	channels#index
62	info	Request completed: GET /admin/channels/new	{"ip": "127.0.0.1", "action": "new", "params": {}, "user_id": 1, "controller": "channels", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:36:05.44303	2025-05-23 13:36:05.44303	channels#new
63	info	Request completed: GET /admin/channels	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "channels", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:36:27.864547	2025-05-23 13:36:27.864547	channels#index
64	info	Request completed: GET /admin/trades	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "trades", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:36:34.806478	2025-05-23 13:36:34.806478	trades#index
65	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:44:01.795494	2025-05-23 13:44:01.795494	dashboard#index
66	info	Request completed: GET /admin/payments	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "payments", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:44:04.890076	2025-05-23 13:44:04.890076	payments#index
67	info	Request completed: GET /admin/logs	{"ip": "127.0.0.1", "action": "logs", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:44:27.193025	2025-05-23 13:44:27.193025	dashboard#logs
68	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:44:32.7094	2025-05-23 13:44:32.7094	dashboard#index
69	info	Request completed: GET /admin/users	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "users", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:44:40.346182	2025-05-23 13:44:40.346182	users#index
70	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:56:28.833965	2025-05-23 13:56:28.833965	dashboard#index
71	info	Request completed: GET /admin/users	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "users", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:56:33.06176	2025-05-23 13:56:33.06176	users#index
72	info	Request completed: GET /admin/subscriptions	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "subscriptions", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:56:38.136746	2025-05-23 13:56:38.136746	subscriptions#index
73	info	Request completed: GET /admin/channels	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "channels", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:56:40.53592	2025-05-23 13:56:40.53592	channels#index
74	info	Request completed: GET /admin/trades	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "trades", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:56:44.569408	2025-05-23 13:56:44.569408	trades#index
75	info	Request completed: GET /admin/payments	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "payments", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:56:46.318797	2025-05-23 13:56:46.318797	payments#index
76	info	Request completed: GET /admin/logs	{"ip": "127.0.0.1", "action": "logs", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:56:48.05554	2025-05-23 13:56:48.05554	dashboard#logs
77	info	Request completed: GET /admin/dashboard	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 13:57:40.803638	2025-05-23 13:57:40.803638	dashboard#index
78	info	Request completed: GET /admin/dashboard	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 14:49:40.204691	2025-05-23 14:49:40.204691	dashboard#index
79	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 14:59:45.403187	2025-05-23 14:59:45.403187	home#index
80	info	Request completed: GET /admin	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 1, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 14:59:45.546644	2025-05-23 14:59:45.546644	dashboard#index
81	info	Request completed: GET /auth/logout	{"ip": "127.0.0.1", "action": "logout", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 14:59:49.492294	2025-05-23 14:59:49.492294	auth#logout
82	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 14:59:49.557131	2025-05-23 14:59:49.557131	home#index
83	info	Request completed: GET /auth/register	{"ip": "127.0.0.1", "action": "register_form", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:00:02.034679	2025-05-23 15:00:02.034679	auth#register_form
84	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:08:15.244263	2025-05-23 15:08:15.244263	home#index
85	info	Request completed: GET /auth/register	{"ip": "127.0.0.1", "action": "register_form", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:08:20.30933	2025-05-23 15:08:20.30933	auth#register_form
86	info	Request completed: POST /auth/register	{"ip": "127.0.0.1", "action": "register", "params": {"user": {"email": "mujeebrathore4@gmail.com", "password": "mujeeb", "full_name": "Test 01", "last_name": "01", "first_name": "Test", "terms_of_service": "1", "password_confirmation": "mujeeb"}, "commit": "Create Account", "authenticity_token": "P2ZYT3RTOEoyXcR7J1ziYYgqj3ClP1sn2oIPcLIz9eXz9-cUdtNFbnLEtMbPXGMdBlwWPJuaR6XAMbY0iwQMAQ"}, "user_id": 2, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:08:45.702318	2025-05-23 15:08:45.702318	auth#register
87	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 2, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:13:59.080309	2025-05-23 15:13:59.080309	home#index
88	info	Request completed: GET /dashboard	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": 2, "controller": "dashboard", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:13:59.335385	2025-05-23 15:13:59.335385	dashboard#index
89	info	Request completed: GET /auth/logout	{"ip": "127.0.0.1", "action": "logout", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:14:44.020326	2025-05-23 15:14:44.020326	auth#logout
90	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:14:44.063713	2025-05-23 15:14:44.063713	home#index
91	info	Request completed: GET /auth/login	{"ip": "127.0.0.1", "action": "login_form", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:14:51.793167	2025-05-23 15:14:51.793167	auth#login_form
92	info	Request completed: GET /auth/register	{"ip": "127.0.0.1", "action": "register_form", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:15:19.215782	2025-05-23 15:15:19.215782	auth#register_form
93	info	Request completed: GET /	{"ip": "127.0.0.1", "action": "index", "params": {}, "user_id": null, "controller": "home", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:27:01.936926	2025-05-23 15:27:01.936926	home#index
94	info	Request completed: GET /auth/register	{"ip": "127.0.0.1", "action": "register_form", "params": {}, "user_id": null, "controller": "auth", "user_agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0"}	2025-05-23 15:27:20.069252	2025-05-23 15:27:20.069252	auth#register_form
\.


--
-- Data for Name: trade_signals; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.trade_signals (id, channel_id, message_content, parsed_data, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: trades; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.trades (id, user_id, trade_signal_id, binance_trade_id, status, amount, "timestamp", created_at, updated_at, pre_trade_data, post_trade_data, error_data, take_profit_data, stop_loss_data, needs_review, review_reason, review_requested_at) FROM stdin;
\.


--
-- Data for Name: user_channel_accesses; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.user_channel_accesses (id, user_id, channel_id, access_type, payment_id, access_start_date, access_end_date, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: mujeeb
--

COPY public.users (id, email, password_digest, discord_id, binance_api_key, encrypted_binance_api_secret, binance_api_secret_iv, subscription_status, created_at, updated_at, full_name, admin, subscription_id, trades_count, subscription_start_date, subscription_end_date) FROM stdin;
1	admin@example.com	$2a$12$MUgWkQtFHSW/av8ypuRVI.vAcFq.TpdqsuD3AnoMfoB2L9E7Bzx2S	\N	\N	\N	\N	active	2025-05-22 15:00:24.149988	2025-05-22 15:00:24.149988	Admin User	t	\N	\N	\N	\N
2	mujeebrathore4@gmail.com	$2a$12$x2aSWcbWlX.urR/puXrQjeEr5.sSffEF/0ifyF7NEz2ArPpN2WY4O	\N	\N	\N	\N	active	2025-05-23 15:08:45.674205	2025-05-23 15:08:45.674205	Test 01	f	1	0	\N	\N
\.


--
-- Name: api_credentials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.api_credentials_id_seq', 1, false);


--
-- Name: channels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.channels_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.notifications_id_seq', 5, true);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.payments_id_seq', 1, false);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.subscriptions_id_seq', 3, true);


--
-- Name: system_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.system_logs_id_seq', 94, true);


--
-- Name: trade_signals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.trade_signals_id_seq', 1, false);


--
-- Name: trades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.trades_id_seq', 1, false);


--
-- Name: user_channel_accesses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.user_channel_accesses_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mujeeb
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: api_credentials api_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.api_credentials
    ADD CONSTRAINT api_credentials_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: channels channels_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: system_logs system_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_pkey PRIMARY KEY (id);


--
-- Name: trade_signals trade_signals_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.trade_signals
    ADD CONSTRAINT trade_signals_pkey PRIMARY KEY (id);


--
-- Name: trades trades_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_pkey PRIMARY KEY (id);


--
-- Name: user_channel_accesses user_channel_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.user_channel_accesses
    ADD CONSTRAINT user_channel_accesses_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_api_credentials_on_user_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_api_credentials_on_user_id ON public.api_credentials USING btree (user_id);


--
-- Name: index_channels_on_channel_type; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_channels_on_channel_type ON public.channels USING btree (channel_type);


--
-- Name: index_channels_on_discord_channel_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE UNIQUE INDEX index_channels_on_discord_channel_id ON public.channels USING btree (discord_channel_id);


--
-- Name: index_channels_on_signal_format; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_channels_on_signal_format ON public.channels USING btree (signal_format);


--
-- Name: index_channels_on_status; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_channels_on_status ON public.channels USING btree (status);


--
-- Name: index_notifications_on_read; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_notifications_on_read ON public.notifications USING btree (read);


--
-- Name: index_notifications_on_user_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_notifications_on_user_id ON public.notifications USING btree (user_id);


--
-- Name: index_payments_on_payment_gateway_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE UNIQUE INDEX index_payments_on_payment_gateway_id ON public.payments USING btree (payment_gateway_id);


--
-- Name: index_payments_on_user_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_payments_on_user_id ON public.payments USING btree (user_id);


--
-- Name: index_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_subscriptions_on_user_id ON public.subscriptions USING btree (user_id);


--
-- Name: index_system_logs_on_created_at; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_system_logs_on_created_at ON public.system_logs USING btree (created_at);


--
-- Name: index_system_logs_on_level; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_system_logs_on_level ON public.system_logs USING btree (level);


--
-- Name: index_trade_signals_on_channel_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_trade_signals_on_channel_id ON public.trade_signals USING btree (channel_id);


--
-- Name: index_trades_on_binance_trade_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE UNIQUE INDEX index_trades_on_binance_trade_id ON public.trades USING btree (binance_trade_id);


--
-- Name: index_trades_on_trade_signal_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_trades_on_trade_signal_id ON public.trades USING btree (trade_signal_id);


--
-- Name: index_trades_on_user_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_trades_on_user_id ON public.trades USING btree (user_id);


--
-- Name: index_user_channel_accesses_on_channel_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_user_channel_accesses_on_channel_id ON public.user_channel_accesses USING btree (channel_id);


--
-- Name: index_user_channel_accesses_on_payment_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_user_channel_accesses_on_payment_id ON public.user_channel_accesses USING btree (payment_id);


--
-- Name: index_user_channel_accesses_on_user_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE INDEX index_user_channel_accesses_on_user_id ON public.user_channel_accesses USING btree (user_id);


--
-- Name: index_user_channel_accesses_on_user_id_and_channel_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE UNIQUE INDEX index_user_channel_accesses_on_user_id_and_channel_id ON public.user_channel_accesses USING btree (user_id, channel_id);


--
-- Name: index_users_on_binance_api_key; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE UNIQUE INDEX index_users_on_binance_api_key ON public.users USING btree (binance_api_key);


--
-- Name: index_users_on_discord_id; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE UNIQUE INDEX index_users_on_discord_id ON public.users USING btree (discord_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: mujeeb
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: user_channel_accesses fk_rails_00bca6f41a; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.user_channel_accesses
    ADD CONSTRAINT fk_rails_00bca6f41a FOREIGN KEY (payment_id) REFERENCES public.payments(id);


--
-- Name: user_channel_accesses fk_rails_01215439d5; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.user_channel_accesses
    ADD CONSTRAINT fk_rails_01215439d5 FOREIGN KEY (channel_id) REFERENCES public.channels(id);


--
-- Name: payments fk_rails_081dc04a02; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_rails_081dc04a02 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: trades fk_rails_12b0ea7696; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT fk_rails_12b0ea7696 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: api_credentials fk_rails_689eb16da8; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.api_credentials
    ADD CONSTRAINT fk_rails_689eb16da8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_channel_accesses fk_rails_73456e7e93; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.user_channel_accesses
    ADD CONSTRAINT fk_rails_73456e7e93 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: subscriptions fk_rails_933bdff476; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_933bdff476 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: notifications fk_rails_b080fb4855; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: trades fk_rails_b336228c05; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT fk_rails_b336228c05 FOREIGN KEY (trade_signal_id) REFERENCES public.trade_signals(id);


--
-- Name: trade_signals fk_rails_ea99f81fb0; Type: FK CONSTRAINT; Schema: public; Owner: mujeeb
--

ALTER TABLE ONLY public.trade_signals
    ADD CONSTRAINT fk_rails_ea99f81fb0 FOREIGN KEY (channel_id) REFERENCES public.channels(id);


--
-- PostgreSQL database dump complete
--

