-- GENERAL
INSERT INTO checklist_templates (tipo_cliente, categoria, item_codigo, item_nombre, orden) VALUES
('todos', 'general', 'nombre_sl', 'Nombre S.L.', 1),
('todos', 'general', 'nif', 'NIF', 2),
('todos', 'general', 'escrituras', 'Escrituras', 3),
('todos', 'general', 'estatutos_sociales', 'Estatutos Sociales', 4),
('todos', 'general', 'escrituras_posteriores', 'Escrituras Posteriores', 5),
('todos', 'general', 'acta_titularidad_real', 'Acta Titularidad Real', 6),
('todos', 'general', 'nota_simple', 'Nota Simple', 7),
('todos', 'general', 'certificado_digital', 'Certificado Digital', 8),
('todos', 'general', 'modelo_036', 'Modelo 036', 9);

-- SEGURIDAD SOCIAL
INSERT INTO checklist_templates (tipo_cliente, categoria, item_codigo, item_nombre, orden) VALUES
('todos', 'seguridad_social', 'ccc', 'CCC', 10),
('todos', 'seguridad_social', 'alta_tgss', 'Alta en TGSS', 11),
('todos', 'seguridad_social', 'alta_administrador', 'Alta Administrador', 12),
('todos', 'seguridad_social', 'acceso_sistema_red', 'Acceso sistema RED', 13);

-- LABORAL
INSERT INTO checklist_templates (tipo_cliente, categoria, item_codigo, item_nombre, orden) VALUES
('todos', 'laboral', 'contratos_empleados', 'Contratos de empleados', 14),
('todos', 'laboral', 'nominas_ano_curso', 'Nominas del año en curso', 15),
('todos', 'laboral', 'nominas_ano_anterior', 'Nominas del año anterior', 16),
('todos', 'laboral', 'modelo_111_presentados', 'Modelo 111 presentados', 17),
('todos', 'laboral', 'borrador_190', 'Borrador 190', 18),
('todos', 'laboral', 'ita', 'ITA', 19),
('todos', 'laboral', 'confirmar_asignacion_ccc', 'Confirmar asignación CCC', 20),
('todos', 'laboral', 'excel_trabajadores_activo', 'Excel trabajadores activo', 21);

-- BANCO
INSERT INTO checklist_templates (tipo_cliente, categoria, item_codigo, item_nombre, orden) VALUES
('todos', 'banco', 'certificado_titularidad_bancos', 'Certificado Titularidad Bancos', 22),
('todos', 'banco', 'iban', 'IBAN', 23);

-- CONTABILIDAD
INSERT INTO checklist_templates (tipo_cliente, categoria, item_codigo, item_nombre, orden) VALUES
('todos', 'contabilidad', 'libro_diario', 'Libro Diario', 24),
('todos', 'contabilidad', 'libro_mayor', 'Libro Mayor', 25),
('todos', 'contabilidad', 'balance', 'Balance', 26),
('todos', 'contabilidad', 'pyg', 'PyG', 27),
('todos', 'contabilidad', 'sumas_saldos', 'Sumas y Saldos', 28),
('todos', 'contabilidad', 'cuadro_cuentas', 'Cuadro de Cuentas', 29),
('todos', 'contabilidad', 'clientes_proveedores', 'Clientes y Proveedores', 30),
('todos', 'contabilidad', 'libro_facturas_emitidas', 'Libro de facturas emitidas', 31),
('todos', 'contabilidad', 'libro_facturas_recibidas', 'Libro de facturas recibidas', 32),
('todos', 'contabilidad', 'libro_gastos', 'Libro de gastos', 33),
('todos', 'contabilidad', 'listado_plan_contable', 'Listado Plan Contable', 34),
('todos', 'contabilidad', 'borrador_347', 'Borrador 347', 35);

-- EXTRAS (flags/datos rojos de la Ficha Cliente)
INSERT INTO checklist_templates (tipo_cliente, categoria, item_codigo, item_nombre, orden, obligatorio) VALUES
('todos', 'general', 'holded_propio', '¿Holded propio?', 36, FALSE),
('todos', 'general', 'trabajan_nominasol', '¿Trabajan con Nominasol?', 37, FALSE),
('todos', 'general', 'contrasena_certificado', 'Contraseña Certificado', 38, TRUE);
