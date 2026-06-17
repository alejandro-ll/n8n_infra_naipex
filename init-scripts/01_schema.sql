-- 1. Función común para actualizar el timestamp de "updated_at"
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 2. Tabla traspasos
CREATE TABLE traspasos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id TEXT UNIQUE NOT NULL,
    nombre_empresa TEXT NOT NULL,
    cif_nif TEXT,
    email_cliente TEXT NOT NULL,
    telefono TEXT,
    tipo_cliente TEXT CHECK (tipo_cliente IN ('SL', 'autonomo', 'patrimonial', 'pendiente')),
    owner_inicial TEXT,
    owner_actual TEXT,
    estado TEXT NOT NULL DEFAULT 'esperando_docs' CHECK (
        estado IN ('esperando_docs', 'completado', 'on_hold', 'stalled', 'archivado')
    ),
    gmail_thread_id TEXT,
    gmail_message_id TEXT,
    drive_folder_root_id TEXT,
    drive_folders JSONB,
    on_hold_until DATE,
    notas TEXT,
    fecha_inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_completado TIMESTAMPTZ,
    last_activity TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_traspasos_estado ON traspasos(estado);
CREATE INDEX idx_traspasos_email ON traspasos(email_cliente);
CREATE INDEX idx_traspasos_last_activity ON traspasos(last_activity);
CREATE INDEX idx_traspasos_owner_actual ON traspasos(owner_actual);

CREATE TRIGGER update_traspasos_updated_at 
    BEFORE UPDATE ON traspasos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. Tabla onboarding_checklist
CREATE TABLE onboarding_checklist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    traspaso_id UUID NOT NULL REFERENCES traspasos(id) ON DELETE CASCADE,
    categoria TEXT NOT NULL CHECK (categoria IN (
        'general', 'seguridad_social', 'contabilidad', 'laboral', 'banco'
    )),
    item_codigo TEXT NOT NULL,
    item_nombre TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (
        estado IN ('pendiente', 'recibido', 'rechazado', 'no_aplica')
    ),
    doc_id UUID,
    drive_file_id TEXT,
    drive_url TEXT,
    validado_por_agente BOOLEAN DEFAULT FALSE,
    notas_validacion TEXT,
    fecha_recibido TIMESTAMPTZ,
    rechazado_motivo TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(traspaso_id, item_codigo)
);

CREATE INDEX idx_checklist_traspaso ON onboarding_checklist(traspaso_id);
CREATE INDEX idx_checklist_estado ON onboarding_checklist(estado);
CREATE INDEX idx_checklist_categoria ON onboarding_checklist(categoria);
CREATE INDEX idx_checklist_pendientes ON onboarding_checklist(traspaso_id, estado) 
    WHERE estado = 'pendiente';

CREATE TRIGGER update_checklist_updated_at 
    BEFORE UPDATE ON onboarding_checklist 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. Tabla docs_recibidos
CREATE TABLE docs_recibidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    traspaso_id UUID NOT NULL REFERENCES traspasos(id) ON DELETE CASCADE,
    checklist_item_id UUID REFERENCES onboarding_checklist(id) ON DELETE SET NULL,
    canal TEXT NOT NULL CHECK (canal IN ('email', 'drive')),
    gmail_message_id TEXT,
    drive_file_id_origen TEXT,
    nombre_original TEXT NOT NULL,
    mime_type TEXT,
    tamano_bytes BIGINT,
    hash_archivo TEXT NOT NULL,
    drive_file_id_final TEXT,
    drive_url TEXT,
    tipo_detectado TEXT,
    confianza TEXT CHECK (confianza IN ('alta', 'media', 'baja')),
    validacion JSONB,
    requiere_revision_humana BOOLEAN DEFAULT FALSE,
    estado TEXT NOT NULL DEFAULT 'procesado' CHECK (
        estado IN ('procesado', 'rechazado', 'duplicado', 'fallido')
    ),
    error_mensaje TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(traspaso_id, hash_archivo)
);

CREATE INDEX idx_docs_traspaso ON docs_recibidos(traspaso_id);
CREATE INDEX idx_docs_estado ON docs_recibidos(estado);
CREATE INDEX idx_docs_hash ON docs_recibidos(hash_archivo);
CREATE INDEX idx_docs_revision_humana ON docs_recibidos(traspaso_id) 
    WHERE requiere_revision_humana = TRUE;
CREATE INDEX idx_docs_gmail_msg ON docs_recibidos(gmail_message_id) 
    WHERE gmail_message_id IS NOT NULL;

-- 5. Tabla jobs_queue
CREATE TABLE jobs_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    traspaso_id UUID REFERENCES traspasos(id) ON DELETE CASCADE,
    canal TEXT NOT NULL CHECK (canal IN ('email', 'drive')),
    gmail_message_id TEXT,
    drive_file_id TEXT,
    estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (
        estado IN ('pendiente', 'procesando', 'completado', 'fallido', 'duplicado')
    ),
    intentos INT NOT NULL DEFAULT 0,
    max_intentos INT NOT NULL DEFAULT 3,
    processing_started_at TIMESTAMPTZ,
    processing_finished_at TIMESTAMPTZ,
    docs_procesados INT DEFAULT 0,
    docs_fallidos INT DEFAULT 0,
    ultimo_error TEXT,
    prioridad INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT canal_id_coherente CHECK (
        (canal = 'email' AND gmail_message_id IS NOT NULL) OR
        (canal = 'drive' AND drive_file_id IS NOT NULL)
    )
);

CREATE INDEX idx_jobs_pendientes ON jobs_queue(estado, created_at) 
    WHERE estado = 'pendiente';
CREATE INDEX idx_jobs_procesando ON jobs_queue(processing_started_at) 
    WHERE estado = 'procesando';
CREATE INDEX idx_jobs_traspaso ON jobs_queue(traspaso_id);
CREATE INDEX idx_jobs_gmail_msg ON jobs_queue(gmail_message_id) 
    WHERE gmail_message_id IS NOT NULL;
CREATE INDEX idx_jobs_drive_file ON jobs_queue(drive_file_id) 
    WHERE drive_file_id IS NOT NULL;

CREATE TRIGGER update_jobs_updated_at 
    BEFORE UPDATE ON jobs_queue 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 6. Tabla clientes (BBDD Final)
CREATE TABLE clientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id TEXT UNIQUE NOT NULL,
    traspaso_id UUID REFERENCES traspasos(id) ON DELETE SET NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_alta DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_baja DATE,
    nombre_empresa TEXT NOT NULL,
    cif_nif TEXT,
    tipo_cliente TEXT CHECK (tipo_cliente IN ('SL', 'autonomo', 'patrimonial')),
    direccion TEXT,
    nombre_admin TEXT,
    correo_admin TEXT,
    owner TEXT,
    servicio TEXT,
    categoria TEXT,
    importe_mensual NUMERIC(10, 2),
    importe_laboral NUMERIC(10, 2),
    modo_contacto TEXT,
    recordatorio_facturas_enviado BOOLEAN DEFAULT FALSE,
    email_contacto_1 TEXT,
    email_contacto_2 TEXT,
    email_contacto_3 TEXT,
    telefono TEXT,
    certificado_digital BOOLEAN DEFAULT FALSE,
    alta_dehu BOOLEAN DEFAULT FALSE,
    entidad_bancaria_1 TEXT,
    cuenta_bancaria_1 TEXT,
    entidad_bancaria_2 TEXT,
    cuenta_bancaria_2 TEXT,
    entidad_bancaria_3 TEXT,
    cuenta_bancaria_3 TEXT,
    holded_id TEXT,
    holded_tipo TEXT,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_clientes_activo ON clientes(activo) WHERE activo = TRUE;
CREATE INDEX idx_clientes_owner ON clientes(owner);
CREATE INDEX idx_clientes_cif ON clientes(cif_nif);
CREATE INDEX idx_clientes_email_admin ON clientes(correo_admin);
CREATE INDEX idx_clientes_holded ON clientes(holded_id) WHERE holded_id IS NOT NULL;

CREATE TRIGGER update_clientes_updated_at 
    BEFORE UPDATE ON clientes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. Tabla checklist_templates
CREATE TABLE checklist_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_cliente TEXT NOT NULL CHECK (tipo_cliente IN (
        'SL', 'autonomo', 'patrimonial', 'todos'
    )),
    categoria TEXT NOT NULL CHECK (categoria IN (
        'general', 'seguridad_social', 'contabilidad', 'laboral', 'banco'
    )),
    item_codigo TEXT NOT NULL,
    item_nombre TEXT NOT NULL,
    orden INT NOT NULL DEFAULT 0,
    obligatorio BOOLEAN DEFAULT TRUE,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tipo_cliente, item_codigo)
);

CREATE INDEX idx_templates_tipo ON checklist_templates(tipo_cliente) WHERE activo = TRUE;

CREATE TRIGGER update_templates_updated_at 
    BEFORE UPDATE ON checklist_templates 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
