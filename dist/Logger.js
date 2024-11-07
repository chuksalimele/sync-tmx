"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Config_1 = require("./Config");
const winston = require('winston');
require('winston-daily-rotate-file');
const { combine, timestamp, json } = winston.format;
var MAX_FILES_DAYS = '14d';
var FILE_DATE_PATTERN = 'YYYY-MM-DD';
const errorFilter = winston.format((info, opts) => {
    return info.level === 'error' ? info : false;
});
const infoFilter = winston.format((info, opts) => {
    return info.level === 'info' ? info : false;
});
const combineLogfileRotateTransport = new winston.transports.DailyRotateFile({
    filename: `${Config_1.Config.STMX_LOG_COMBINE}-%DATE%.log`,
    datePattern: FILE_DATE_PATTERN,
    maxFiles: MAX_FILES_DAYS,
});
const appInfoLogfileRotateTransport = new winston.transports.DailyRotateFile({
    filename: `${Config_1.Config.STMX_LOG_INFO}-%DATE%.log`,
    level: 'info',
    format: combine(infoFilter(), timestamp(), json()),
    datePattern: FILE_DATE_PATTERN,
    maxFiles: MAX_FILES_DAYS,
});
const appErrorLogfileRotateTransport = new winston.transports.DailyRotateFile({
    filename: `${Config_1.Config.STMX_LOG_ERROR}-%DATE%.log`,
    level: 'error',
    format: combine(errorFilter(), timestamp(), json()),
    datePattern: FILE_DATE_PATTERN,
    maxFiles: MAX_FILES_DAYS,
});
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: combine(timestamp(), json()),
    transports: [combineLogfileRotateTransport,
        appInfoLogfileRotateTransport,
        appErrorLogfileRotateTransport],
});
//logger.error("Testing error log");
exports.default = logger;
//# sourceMappingURL=Logger.js.map