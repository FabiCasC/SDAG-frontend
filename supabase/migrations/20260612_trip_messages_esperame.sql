-- Permite mensajes de tipo "esperame" en el chat del viaje.
alter type public.chat_message_type add value if not exists 'esperame';
