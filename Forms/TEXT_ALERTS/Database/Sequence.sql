-- ====================================
-- TEXT ALERTS SEQUENCE...
-- ====================================
DROP SEQUENCE TEXT_ALERTS_SEQ;
CREATE SEQUENCE TEXT_ALERTS_SEQ
MINVALUE   1
MAXVALUE   999999999999
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;