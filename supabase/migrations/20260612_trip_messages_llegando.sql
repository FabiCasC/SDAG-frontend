-- Permite mensajes de tipo "llegando" en el chat del viaje.
alter type public.chat_message_type add value if not exists 'llegando';
