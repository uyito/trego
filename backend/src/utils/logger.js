const winston = require('winston');

const { combine, timestamp, errors, json, colorize, simple } = winston.format;

// Custom log format
const customFormat = winston.format.printf(({ timestamp, level, message, ...meta }) => {
  let log = `${timestamp} [${level.toUpperCase()}]: ${message}`;
  
  if (Object.keys(meta).length > 0) {
    log += `\n${JSON.stringify(meta, null, 2)}`;
  }
  
  return log;
});

// Create logger instance
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(
    errors({ stack: true }),
    timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    process.env.NODE_ENV === 'production' ? json() : combine(colorize(), customFormat)
  ),
  defaultMeta: { service: 'trego-backend' },
  transports: [
    // Console transport for development
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'production' 
        ? json() 
        : combine(colorize(), simple())
    }),
  ],
});

// Add file transports for production
if (process.env.NODE_ENV === 'production') {
  logger.add(new winston.transports.File({
    filename: 'logs/error.log',
    level: 'error',
    format: combine(timestamp(), errors({ stack: true }), json()),
    maxsize: 5242880, // 5MB
    maxFiles: 5,
  }));

  logger.add(new winston.transports.File({
    filename: 'logs/combined.log',
    format: combine(timestamp(), errors({ stack: true }), json()),
    maxsize: 5242880, // 5MB
    maxFiles: 5,
  }));
}

// Create a stream object with 'write' function for morgan
logger.stream = {
  write: (message) => {
    logger.info(message.trim());
  },
};

// Log uncaught exceptions and unhandled rejections
logger.exceptions.handle(
  new winston.transports.File({ filename: 'logs/exceptions.log' })
);

logger.rejections.handle(
  new winston.transports.File({ filename: 'logs/rejections.log' })
);

module.exports = logger;