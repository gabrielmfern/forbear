import path from "node:path";
import { createRequire } from "node:module";

const cwd = process.cwd();
const ts = createRequire(path.join(cwd, "package.json"))("typescript");

function transformer(ctx) {
    const factory = ctx.factory;

    function visit(node) {
        if (ts.isSourceFile(node)) {
            return factory.updateSourceFile(node, visitStatements(node.statements));
        }
        if (ts.isBlock(node)) {
            return factory.updateBlock(node, visitStatements(node.statements));
        }
        if (ts.isModuleBlock(node)) {
            return factory.updateModuleBlock(node, visitStatements(node.statements));
        }
        if (ts.isCaseClause(node)) {
            return factory.updateCaseClause(node, visit(node.expression), visitStatements(node.statements));
        }
        if (ts.isDefaultClause(node)) {
            return factory.updateDefaultClause(node, visitStatements(node.statements));
        }

        if (ts.isArrowFunction(node)) {
            let body = node.body;
            while (ts.isParenthesizedExpression(body)) body = body.expression;
            if (ts.isJsxElement(body) || ts.isJsxSelfClosingElement(body) || ts.isJsxFragment(body)) {
                return factory.updateArrowFunction(
                    node,
                    node.modifiers,
                    node.typeParameters,
                    node.parameters,
                    node.type,
                    node.equalsGreaterThanToken,
                    factory.createBlock(jsxToCalls(body).map((expr) => factory.createExpressionStatement(expr)), true),
                );
            }
        }
        if (ts.isJsxElement(node) || ts.isJsxSelfClosingElement(node) || ts.isJsxFragment(node)) {
            const calls = jsxToCalls(node);
            if (!calls.length) return factory.createVoidZero();
            if (calls.length === 1) return calls[0];
            return factory.createParenthesizedExpression(factory.createCommaListExpression(calls));
        }
        return ts.visitEachChild(node, visit, ctx);
    }

    function visitStatements(statements) {
        const out = [];
        for (const stmt of statements) {
            let expr = stmt.expression;
            if (ts.isExpressionStatement(stmt)) {
                while (expr && ts.isParenthesizedExpression(expr)) expr = expr.expression;
            }
            if (ts.isExpressionStatement(stmt) && expr && (ts.isJsxElement(expr) || ts.isJsxSelfClosingElement(expr) || ts.isJsxFragment(expr))) {
                for (const call of jsxToCalls(expr)) out.push(factory.createExpressionStatement(call));
                continue;
            }
            out.push(visit(stmt));
        }
        return out;
    }

    function jsxToCalls(node) {
        const calls = [];
        let children;
        if (ts.isJsxFragment(node)) {
            children = node.children;
        } else {
            const openEl = ts.isJsxElement(node) ? node.openingElement : node;
            const tag = openEl.tagName;
            if (!ts.isIdentifier(tag) || tag.text !== "element") {
                const src = tag.getSourceFile();
                const { line, character } = src.getLineAndCharacterOfPosition(tag.getStart());
                throw new Error(`${src.fileName}:${line + 1}:${character + 1}: JSX host tag must be element`);
            }

            const src = openEl.getSourceFile();
            const { line, character } =
                src.getLineAndCharacterOfPosition(openEl.getStart());
            let key = factory.createStringLiteral(
                `${src.fileName}:${line + 1}:${character + 1}`,
            );
            const properties = [];
            for (const attr of openEl.attributes.properties) {
                if (ts.isJsxSpreadAttribute(attr)) {
                    properties.push(factory.createSpreadAssignment(visit(attr.expression)));
                    continue;
                }
                const name = attr.name;
                if (!ts.isIdentifier(name)) {
                    const src = name.getSourceFile();
                    const { line, character } = src.getLineAndCharacterOfPosition(name.getStart());
                    throw new Error(`${src.fileName}:${line + 1}:${character + 1}: JSX attribute name must be an identifier`);
                }
                let value;
                if (!attr.initializer) {
                    value = factory.createTrue();
                } else if (ts.isJsxExpression(attr.initializer)) {
                    if (!attr.initializer.expression) {
                        const src = attr.getSourceFile();
                        const { line, character } = src.getLineAndCharacterOfPosition(attr.getStart());
                        throw new Error(`${src.fileName}:${line + 1}:${character + 1}: empty JSX expression`);
                    }
                    value = visit(attr.initializer.expression);
                } else {
                    value = visit(attr.initializer);
                }
                if (name.text === "key") {
                    key = value;
                    continue;
                }
                properties.push(factory.createPropertyAssignment(factory.createIdentifier(name.text), value));
            }

            const args = [];
            if (properties.length) args.push(factory.createObjectLiteralExpression(properties, true));
            if (key) args.push(key);
            calls.push(factory.createCallExpression(factory.createIdentifier("open"), undefined, args));
            if (ts.isJsxElement(node)) children = node.children;
        }

        if (children) {
            for (const child of children) {
                if (ts.isJsxText(child)) {
                    if (child.containsOnlyTriviaWhiteSpaces) continue;
                    const value = child.text.trim();
                    if (!value) continue;
                    calls.push(factory.createCallExpression(factory.createIdentifier("text"), undefined, [factory.createStringLiteral(value)]));
                    continue;
                }
                if (ts.isJsxExpression(child)) {
                    if (!child.expression) continue;
                    let expr = child.expression;
                    while (ts.isParenthesizedExpression(expr)) expr = expr.expression;
                    if (ts.isJsxElement(expr) || ts.isJsxSelfClosingElement(expr) || ts.isJsxFragment(expr)) {
                        calls.push(...jsxToCalls(expr));
                        continue;
                    }
                    let found = false;
                    const walk = (n) => {
                        if (found || !n) return;
                        if (ts.isJsxElement(n) || ts.isJsxSelfClosingElement(n) || ts.isJsxFragment(n)) {
                            found = true;
                            return;
                        }
                        ts.forEachChild(n, walk);
                    };
                    walk(expr);
                    if (found) calls.push(visit(child.expression));
                    else calls.push(factory.createCallExpression(factory.createIdentifier("text"), undefined, [visit(child.expression)]));
                    continue;
                }
                if (ts.isJsxElement(child) || ts.isJsxSelfClosingElement(child) || ts.isJsxFragment(child)) {
                    calls.push(...jsxToCalls(child));
                }
            }
        }

        if (!ts.isJsxFragment(node)) {
            calls.push(factory.createCallExpression(factory.createIdentifier("close"), undefined, []));
        }
        return calls;
    }

    return (sf) => visit(sf);
}

const configPath = ts.findConfigFile(cwd, ts.sys.fileExists, "tsconfig.json");
if (!configPath) {
    throw new Error("tsconfig.json not found");
}
const configFile = ts.readConfigFile(configPath, ts.sys.readFile);
if (configFile.error) {
    throw new Error(ts.flattenDiagnosticMessageText(configFile.error.messageText, "\n"));
}
const parsed = ts.parseJsonConfigFileContent(configFile.config, ts.sys, cwd);
const options = {
    ...parsed.options,
    noEmit: false,
    jsx: ts.JsxEmit.Preserve,
};
const program = ts.createProgram({ rootNames: parsed.fileNames, options });
const diagnostics = ts.getPreEmitDiagnostics(program);
for (const diagnostic of diagnostics) {
    let loc = "";
    if (diagnostic.file && diagnostic.start != null) {
        const { line, character } = diagnostic.file.getLineAndCharacterOfPosition(diagnostic.start);
        loc = `${diagnostic.file.fileName}:${line + 1}:${character + 1}: `;
    }
    console.error(loc + ts.flattenDiagnosticMessageText(diagnostic.messageText, "\n"));
}
if (diagnostics.some((d) => d.category === ts.DiagnosticCategory.Error)) {
    process.exit(1);
}
const emitted = program.emit(
    undefined,
    (fileName, text, writeByteOrderMark) => {
        if (fileName.endsWith(".jsx")) fileName = fileName.slice(0, -1);
        ts.sys.writeFile(fileName, text, writeByteOrderMark);
    },
    undefined,
    false,
    { before: [transformer] },
);
for (const diagnostic of emitted.diagnostics) {
    console.error(ts.flattenDiagnosticMessageText(diagnostic.messageText, "\n"));
}
if (emitted.emitSkipped) {
    process.exit(1);
}
