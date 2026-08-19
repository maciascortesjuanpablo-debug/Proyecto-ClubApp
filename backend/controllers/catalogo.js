import { catalogoModel } from '../models/catalogo.js';

// ===== ROLES =====

export const listarRoles = async (req, res) => {
    try {
        const roles = await catalogoModel.listarRoles();
        return res.status(200).json(roles);
    } catch (error) {
        console.error('Error al listar roles:', error);
        return res.status(500).json({ 
            error: "Error al obtener los roles" 
        });
    }
};

export const obtenerRol = async (req, res) => {
    try {
        const { id } = req.params;
        const rol = await catalogoModel.buscarRolPorId(id);

        if (!rol) {
            return res.status(404).json({ 
                error: "Rol no encontrado" 
            });
        }

        return res.status(200).json(rol);
    } catch (error) {
        console.error('Error al obtener rol:', error);
        return res.status(500).json({ 
            error: "Error al obtener el rol" 
        });
    }
};

// ===== DEPORTES =====

export const listarDeportes = async (req, res) => {
    try {
        const deportes = await catalogoModel.listarDeportes();
        return res.status(200).json(deportes);
    } catch (error) {
        console.error('Error al listar deportes:', error);
        return res.status(500).json({ 
            error: "Error al obtener los deportes" 
        });
    }
};

export const obtenerDeporte = async (req, res) => {
    try {
        const { id } = req.params;
        const deporte = await catalogoModel.buscarDeportePorId(id);

        if (!deporte) {
            return res.status(404).json({ 
                error: "Deporte no encontrado" 
            });
        }

        return res.status(200).json(deporte);
    } catch (error) {
        console.error('Error al obtener deporte:', error);
        return res.status(500).json({ 
            error: "Error al obtener el deporte" 
        });
    }
};

// ===== FORMATOS =====

export const listarFormatos = async (req, res) => {
    try {
        const formatos = await catalogoModel.listarFormatos();
        return res.status(200).json(formatos);
    } catch (error) {
        console.error('Error al listar formatos:', error);
        return res.status(500).json({ 
            error: "Error al obtener los formatos" 
        });
    }
};

export const obtenerFormato = async (req, res) => {
    try {
        const { id } = req.params;
        const formato = await catalogoModel.buscarFormatoPorId(id);

        if (!formato) {
            return res.status(404).json({ 
                error: "Formato no encontrado" 
            });
        }

        return res.status(200).json(formato);
    } catch (error) {
        console.error('Error al obtener formato:', error);
        return res.status(500).json({ 
            error: "Error al obtener el formato" 
        });
    }
};