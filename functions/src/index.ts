
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {defineString} from "firebase-functions/params";
import {GoogleGenerativeAI, GenerativeModel} from "@google/generative-ai";
import sgMail from "@sendgrid/mail";

const GEMINI_API_KEY_PARAM = defineString("GEMINI_KEY");
const SENDGRID_API_KEY_PARAM = defineString("SENDGRID_KEY");

export const callGeminiChat = onCall({cors: true}, async (request) => {
  const GEMINI_API_KEY = GEMINI_API_KEY_PARAM.value();

  if (!GEMINI_API_KEY) {
    logger.error(
      "Variável de ambiente 'GEMINI_KEY' não encontrada."
    );
    throw new HttpsError(
      "internal",
      "Configuração do servidor (Gemini) incompleta."
    );
  }

  const geminiModel: GenerativeModel = new GoogleGenerativeAI(
    GEMINI_API_KEY
  ).getGenerativeModel({
    model: "gemini-2.5-flash-lite",
    generationConfig: {
      temperature: 0.5,
    },
  });

  const text = request.data.text;
  if (!text || typeof text !== "string") {
    logger.error("Requisição sem texto.", request.data);
    throw new HttpsError(
      "invalid-argument",
      "A função deve ser chamada com um argumento 'text'."
    );
  }

  try {
    const result = await geminiModel.generateContent(text);
    const response = await result.response;
    const modelResponse = response.text();
    return {text: modelResponse};
  } catch (e) {
    logger.error("Erro ao chamar a API Gemini:", e);
    throw new HttpsError(
      "internal",
      "Não foi possível processar a solicitação."
    );
  }
});

export const onClienteAtivado = onDocumentUpdated(
  {
    document: "clientes/{clienteId}",
  },
  async (event) => {
    const SENDGRID_API_KEY = SENDGRID_API_KEY_PARAM.value();

    if (!SENDGRID_API_KEY) {
      logger.error(
        "Variável 'SENDGRID_KEY' não foi configurada. Abortando."
      );
      return;
    }

    sgMail.setApiKey(SENDGRID_API_KEY);

    if (!event.data) {
      logger.log("Evento sem dados, saindo da função.");
      return;
    }

    const dataBefore = event.data.before.data();
    const dataAfter = event.data.after.data();
    const statusBefore = dataBefore.statusCliente;
    const statusAfter = dataAfter.statusCliente;

    if (statusBefore === statusAfter || statusAfter !== "Ativo") {
      logger.log(
        `Status não mudou para 'Ativo' para ${event.params.clienteId}.`
      );
      return;
    }

    logger.info(`Cliente ${dataAfter.nomeFantasia} ativado. Enviando e-mail.`);

    const msg = {
      to: "jarbascow@gmail.com",
      from: {
        name: "MaicoSoft CRM",
        email: "nngds4444@gmail.com",
      },
      subject: `Novo Cliente Ativado: ${dataAfter.nomeFantasia}`,
      html: `
        <h1>Novo Cliente Ativado no Sistema</h1>
        <p>O cliente <strong>${dataAfter.nomeFantasia || "Sem nome"}
        </strong> (Cód: ${dataAfter.codigo || "N/A"}) foi ativado.</p>
        <h2>Dados do Cliente</h2>
        <ul>
            <li><strong>Nome Fantasia:
            </strong> ${dataAfter.nomeFantasia || "Não informado"}</li>
            <li><strong>CNPJ/CPF:
            </strong> ${dataAfter.cnpjCpf || "Não informado"}</li>
        </ul>
        <h2>Contato Principal</h2>
        <ul>
            <li><strong>Nome:
            </strong> ${dataAfter.nomeContato || "Não informado"}</li>
            <li><strong>E-mail:
            </strong> ${dataAfter.emailContato || "Não informado"}</li>
            <li><strong>Telefone:
            </strong> ${dataAfter.telefoneContato || "Não informado"}</li>
        </ul>
      `,
    };

    try {
      await sgMail.send(msg);
      logger.info(`E-mail para o cliente ${event.params.clienteId} enviado!`);
    } catch (error) {
      logger.error(`Erro ao enviar: ${event.params.clienteId}:`, error);
      if (error instanceof Error && "response" in error) {
        logger.error(
          "Detalhes do erro do SendGrid:",
          (error as any).response?.body
        );
      }
    }
  }
);

