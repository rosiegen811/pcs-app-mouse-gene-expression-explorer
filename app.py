#!/usr/local/Python-3.12/bin/python3

from flask import Flask, render_template, request
from dotenv import load_dotenv
from pathlib import Path
from statistics import median
import os
import mariadb
import traceback

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

app = Flask(__name__)

def get_connection():
    return mariadb.connect(
        host="bioed-new.bu.edu",
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database="Team10",
        port = 4253)

@app.route('/')
def home():
    # Add some sample stats for the dashboard
    stats = {
        'total_samples': '192',
        'total_genes': '22,000+'
    }
    return render_template('index.html', 
                         title="PCS-APP Mouse Gene Expression Explorer",
                         active_page="home",
                         team="Selvakumar, Swathy • Genel, Rosalynn • Castro, Alan Alfonso",
                         **stats)

@app.route('/gene_lookup')  
def gene_lookup():
    try:
        gene = request.args.get("gene", "").strip()
        tissue = request.args.get("tissue", "All")
        age = request.args.get("age", "All")
        genotype = request.args.get("genotype", "All")
        sex = request.args.get("sex", "All")
        diet = request.args.get("diet", "All")
        contrast = request.args.get("contrast", "None")
        
        show_de = contrast != "None"
    
        expression_summary = []
        differential_expression = []
        sample_rows = []
        across_ages = []
    
        if gene:
            conn = get_connection()
            cursor = conn.cursor()
    
            # 1. Differential Expression table
            de_query = """
                SELECT
                    c.Name,
                    c.Tissue,
                    c.Age,
                    d.PAdj,
                    d.Log2FC
                FROM Genes g
                JOIN DifferentialExpressionData d
                    ON g.GeneID = d.GeneID
                JOIN Contrasts c
                    ON d.ContrastID = c.ContrastID
                WHERE LOWER(g.GeneName) = LOWER(?)
            """
    
            de_params = [gene]
    
            if tissue != "All":
                de_query += " AND c.Tissue = ?"
                de_params.append(tissue)
    
            if age != "All":
                de_query += " AND c.Age = ?"
                de_params.append(age)
    
            if contrast == "None":
                de_query += " AND 1 = 0"
            elif contrast != "All":
                de_query += " AND c.Name = ?"
                de_params.append(contrast)
    
            cursor.execute(de_query, de_params)
    
            for name, tissue_val, age_val, padj, log2fc in cursor.fetchall():
                differential_expression.append({
                    "contrast": name,
                    "tissue": tissue_val,
                    "age": age_val,
                    "fdr": padj,
                    "log2fc": log2fc
                })
    
            # 2. Expression Summary
            summary_query = """
                SELECT
                    sm.Genotype,
                    sm.Diet,
                    nc.NormalisedValue
                FROM Genes g
                JOIN NormalisedCounts nc
                    ON g.GeneID = nc.GeneID
                JOIN SampleMetadata sm
                    ON nc.MouseID = sm.MouseID
                WHERE LOWER(g.GeneName) = LOWER(?)
            """
            
            summary_params = [gene]
            
            if tissue != "All":
                summary_query += " AND nc.TissueLocation = ?"
                summary_params.append(tissue)
            
            if age != "All":
                summary_query += " AND CAST(sm.Age AS CHAR) LIKE ?"
                summary_params.append(f"%{age}%")
            
            if contrast == "APP Supplemented vs APP Control":
                summary_query += " AND sm.Genotype = ? AND sm.Diet IN (?, ?)"
                summary_params.extend(["APP", "Supplemented", "Control"])
            
            elif contrast == "WT Supplemented vs WT Control":
                summary_query += " AND sm.Genotype = ? AND sm.Diet IN (?, ?)"
                summary_params.extend(["WT", "Supplemented", "Control"])
            
            elif contrast == "APP vs WT":
                summary_query += " AND sm.Diet = ? AND sm.Genotype IN (?, ?)"
                summary_params.extend(["Control", "APP", "WT"])
            
            else:
                if genotype != "All":
                    summary_query += " AND sm.Genotype = ?"
                    summary_params.append(genotype)
            
                if diet != "All":
                    summary_query += " AND sm.Diet = ?"
                    summary_params.append(diet)
            
            if sex != "All":
                summary_query += " AND sm.Sex = ?"
                summary_params.append(sex)
            
            cursor.execute(summary_query, summary_params)
            rows = cursor.fetchall()
            
            groups = {}
            
            for genotype_val, diet_val, value in rows:
                if value is not None:
                    if diet_val == "Supplemented":
                        group_name = f"{genotype_val} Supplemented"
                    else:
                        group_name = genotype_val
            
                    groups.setdefault(group_name, []).append(float(value))
            
            if contrast == "APP vs WT":
                group_order = ["APP", "WT"]
            
            elif contrast == "APP Supplemented vs APP Control":
                group_order = ["APP Supplemented", "APP"]
            
            elif contrast == "WT Supplemented vs WT Control":
                group_order = ["WT Supplemented", "WT"]
            
            else:
                group_order = ["APP", "APP Supplemented", "WT", "WT Supplemented"]
            
            for group_name in group_order:
                values = groups.get(group_name)
                if values:
                    expression_summary.append({
                        "group": group_name,
                        "n": len(values),
                        "mean": round(sum(values) / len(values), 4),
                        "median": round(median(values), 4)
                    })
    
            # 3. Per-sample table
            sample_query = """
                SELECT
                    sm.MouseID,
                    sm.Genotype,
                    sm.Diet,
                    sm.Sex,
                    sm.Age,
                    nc.TissueLocation,
                    nc.NormalisedValue
                FROM Genes g
                JOIN NormalisedCounts nc
                    ON g.GeneID = nc.GeneID
                JOIN SampleMetadata sm
                    ON nc.MouseID = sm.MouseID
                WHERE LOWER(g.GeneName) = LOWER(?)
            """
    
            sample_params = [gene]
    
            if tissue != "All":
                sample_query += " AND nc.TissueLocation = ?"
                sample_params.append(tissue)
    
            if age != "All":
                sample_query += " AND CAST(sm.Age AS CHAR) LIKE ?"
                sample_params.append(f"%{age}%")
    
            if contrast == "APP Supplemented vs APP Control":
                sample_query += " AND sm.Genotype = ? AND sm.Diet IN (?, ?)"
                sample_params.extend(["APP", "Supplemented", "Control"])
            
            elif contrast == "WT Supplemented vs WT Control":
                sample_query += " AND sm.Genotype = ? AND sm.Diet IN (?, ?)"
                sample_params.extend(["WT", "Supplemented", "Control"])
            
            elif contrast == "APP vs WT":
                sample_query += " AND sm.Diet = ? AND sm.Genotype IN (?, ?)"
                sample_params.extend(["Control", "APP", "WT"])
            
            else:
                if genotype != "All":
                    sample_query += " AND sm.Genotype = ?"
                    sample_params.append(genotype)
            
                if diet != "All":
                    sample_query += " AND sm.Diet = ?"
                    sample_params.append(diet)
            
            if sex != "All":
                sample_query += " AND sm.Sex = ?"
                sample_params.append(sex)
    
            cursor.execute(sample_query, sample_params)
    
            for mouse_id, genotype_val, diet_val, sex_val, age_val, tissue_val, expr in cursor.fetchall():
                sample_rows.append({
                    "mouse_id": mouse_id,
                    "genotype": genotype_val,
                    "diet": diet_val,
                    "sex": sex_val,
                    "age": age_val,
                    "tissue": tissue_val,
                    "expression": expr
                })
            
            # 4. Across Ages Summary
            ages_query = """
                SELECT
                    c.Tissue,
                    c.Age,
                    d.Log2FC,
                    d.PAdj
                FROM Genes g
                JOIN DifferentialExpressionData d
                    ON g.GeneID = d.GeneID
                JOIN Contrasts c
                    ON d.ContrastID = c.ContrastID
                WHERE LOWER(g.GeneName) = LOWER(?)
            """
            
            ages_params = [gene]
            
            if tissue != "All":
                ages_query += " AND c.Tissue = ?"
                ages_params.append(tissue)
            
            if contrast == "None":
                ages_query += " AND 1 = 0"
            elif contrast != "All":
                ages_query += " AND c.Name = ?"
                ages_params.append(contrast)
            
            ages_query += " ORDER BY c.Tissue, c.Age + 0"
            
            cursor.execute(ages_query, ages_params)
            
            for tissue_val, age_val, log2fc, padj in cursor.fetchall():
                across_ages.append({
                    "tissue": tissue_val,
                    "age": age_val,
                    "log2fc": log2fc,
                    "fdr": padj
                })
    
            cursor.close()
            conn.close()
    
        if request.args.get("ajax") == "1":
            return render_template(
                "gene_lookup_results.html",
                gene=gene,
                tissue=tissue,
                age=age,
                genotype=genotype,
                sex=sex,
                diet=diet,
                contrast=contrast,
                show_de=show_de,
                expression_summary=expression_summary,
                differential_expression=differential_expression,
                sample_rows=sample_rows,
                across_ages=across_ages
            )
    
        return render_template(
            "gene_lookup.html",
            title="🔍 Single Gene Expression Lookup",
            active_page="gene_lookup",
            gene=gene,
            tissue=tissue,
            age=age,
            genotype=genotype,
            sex=sex,
            diet=diet,
            contrast=contrast,
            show_de=show_de,
            expression_summary=expression_summary,
            differential_expression=differential_expression,
            sample_rows=sample_rows,
            across_ages=across_ages,
        )
    except Exception:
        return f"<pre>{traceback.format_exc()}</pre>"
        
@app.route('/contrast_results')
def contrast_results():
    try: 
        tissue = request.args.get("tissue", "Cortex")
        age = request.args.get("age", "3")
        contrast = request.args.get("contrast", "APP vs WT")
        direction = request.args.get("direction", "Both")
        fdr = request.args.get("fdr", "0.05")
        gene_name = request.args.get("gene_name", "").strip()
    
        de_results = []
        volcano_results = []
    
        conn = get_connection()
        cursor = conn.cursor()
        
        has_query = len(request.args) > 0
    
        cursor.execute("SELECT COUNT(*) FROM Contrasts")
        total_contrasts = cursor.fetchone()[0]
    
        cursor.execute("SELECT COUNT(*) FROM DifferentialExpressionData WHERE PAdj < 0.05")
        significant_genes = cursor.fetchone()[0]
    
        cursor.execute("SELECT COUNT(*) FROM DifferentialExpressionData WHERE PAdj < 0.001")
        highly_significant = cursor.fetchone()[0]
    
        stats = {
            "total_contrasts": total_contrasts,
            "significant_genes": significant_genes,
            "highly_significant": highly_significant
        }
    
        if has_query:
            query = """
                SELECT
                    g.GeneID,
                    g.GeneName,
                    c.Age,
                    c.Tissue,
                    c.Name,
                    c.ContrastGroup1,
                    c.ContrastGroup2,
                    d.Log2FC,
                    d.PAdj
                FROM DifferentialExpressionData d
                JOIN Genes g
                    ON d.GeneID = g.GeneID
                JOIN Contrasts c
                    ON d.ContrastID = c.ContrastID
                WHERE d.PAdj IS NOT NULL
                    AND d.PAdj > 0
                    AND d.PAdj <= ?
            """
        
            params = [float(fdr)]
        
            if tissue != "All":
                query += " AND c.Tissue = ?"
                params.append(tissue)
        
            if age != "All":
                query += " AND c.Age = ?"
                params.append(age)
        
            if contrast:
                query += " AND c.Name = ?"
                params.append(contrast)
        
            if gene_name:
                query += " AND g.GeneName LIKE ?"
                params.append(f"%{gene_name}%")
        
            if direction == "Upregulated":
                query += " AND d.Log2FC > 0"
            elif direction == "Downregulated":
                query += " AND d.Log2FC < 0"
        
            query += """
               ORDER BY
                   d.PAdj ASC,
                   ABS(d.Log2FC) DESC,
                   g.GeneName ASC
               LIMIT 100
              """
        
            cursor.execute(query, params)
        
            for gene_id, gene, age_val, tissue_val, contrast_name, group1, group2, log2fc, padj in cursor.fetchall():
        
                mean1 = None
                mean2 = None
        
                # Mean expression for Group 1
                mean_query_1 = """
                    SELECT AVG(nc.NormalisedValue)
                    FROM NormalisedCounts nc
                    JOIN SampleMetadata sm
                        ON nc.MouseID = sm.MouseID
                    WHERE nc.GeneID = ?
                      AND nc.TissueLocation = ?
                      AND CAST(sm.Age AS CHAR) LIKE ?
                """
        
                mean_params_1 = [gene_id, tissue_val, f"%{age_val}%"]
        
                if group1 == "APP":
                    mean_query_1 += " AND sm.Genotype = ?"
                    mean_params_1.append("APP")
                elif group1 == "WT":
                    mean_query_1 += " AND sm.Genotype = ?"
                    mean_params_1.append("WT")
                elif group1 == "Supplemented":
                    mean_query_1 += " AND sm.Diet = ?"
                    mean_params_1.append("Supplemented")
        
                cursor.execute(mean_query_1, mean_params_1)
                mean1 = cursor.fetchone()[0]
        
                # Mean expression for Group 2
                mean_query_2 = """
                    SELECT AVG(nc.NormalisedValue)
                    FROM NormalisedCounts nc
                    JOIN SampleMetadata sm
                        ON nc.MouseID = sm.MouseID
                    WHERE nc.GeneID = ?
                      AND nc.TissueLocation = ?
                      AND CAST(sm.Age AS CHAR) LIKE ?
                """
        
                mean_params_2 = [gene_id, tissue_val, f"%{age_val}%"]
        
                if group2 == "APP":
                    mean_query_2 += " AND sm.Genotype = ?"
                    mean_params_2.append("APP")
                elif group2 == "WT":
                    mean_query_2 += " AND sm.Genotype = ?"
                    mean_params_2.append("WT")
                elif group2 == "Control":
                    mean_query_2 += " AND sm.Diet = ?"
                    mean_params_2.append("Control")
                elif group2 == "Supplemented":
                    mean_query_2 += " AND sm.Diet = ?"
                    mean_params_2.append("Supplemented")
        
                cursor.execute(mean_query_2, mean_params_2)
                mean2 = cursor.fetchone()[0]
        
                padj_float = float(padj) if padj is not None else None
                
                de_results.append({
                    "gene_name": gene,
                    "age": age_val,
                    "tissue": tissue_val,
                    "comparison": contrast_name,
                    "log2_fold_change": float(log2fc) if log2fc is not None else None,
                    "padj": padj_float,
                    "volcano_padj": padj_float if padj_float and padj_float > 0 else 1e-16,
                    "mean_group1": float(mean1) if mean1 is not None else None,
                    "mean_group2": float(mean2) if mean2 is not None else None
                })
                
            volcano_query = """
                SELECT
                    g.GeneName,
                    d.Log2FC,
                    d.PAdj
                FROM DifferentialExpressionData d
                JOIN Genes g
                    ON d.GeneID = g.GeneID
                JOIN Contrasts c
                    ON d.ContrastID = c.ContrastID
                WHERE d.PAdj IS NOT NULL
                    AND d.PAdj > 0
            """
            
            volcano_params = []
            
            if tissue != "All":
                volcano_query += " AND c.Tissue = ?"
                volcano_params.append(tissue)
            
            if age != "All":
                volcano_query += " AND c.Age = ?"
                volcano_params.append(age)
            
            if contrast:
                volcano_query += " AND c.Name = ?"
                volcano_params.append(contrast)
            
            if gene_name:
                volcano_query += " AND g.GeneName LIKE ?"
                volcano_params.append(f"%{gene_name}%")
            
            if direction == "Upregulated":
                volcano_query += " AND d.Log2FC > 0"
            elif direction == "Downregulated":
                volcano_query += " AND d.Log2FC < 0"
            
            cursor.execute(volcano_query, volcano_params)
            
            volcano_rows = cursor.fetchall()
    
            nonzero_padjs = [
                float(padj)
                for gene, log2fc, padj in volcano_rows
                if padj is not None and float(padj) > 0
            ]
            
            min_nonzero_padj = min(nonzero_padjs) if nonzero_padjs else 1e-16
            
            for gene, log2fc, padj in volcano_rows:
                padj_float = float(padj) if padj is not None else None
            
                volcano_results.append({
                    "gene_name": gene,
                    "log2_fold_change": float(log2fc) if log2fc is not None else None,
                    "padj": float(padj),
                    "volcano_padj": padj_float if padj_float and padj_float > 0 else min_nonzero_padj
                })
    
        cursor.close()
        conn.close()
    
        if request.args.get("ajax") == "1":
            return render_template(
                "contrast_results_partial.html",
                stats=stats,
                de_results=de_results,
                volcano_results=volcano_results
            )
    
        return render_template(
            "contrast_results.html",
            title="Differential Expression Results",
            active_page="contrast_results",
            stats=stats,
            de_results=de_results,
            volcano_results=volcano_results
        )
    
    except Exception:
        return f"<pre>{traceback.format_exc()}</pre>"

@app.route('/help')
def help_page():
    return render_template('help.html', title="Help & User Guide", active_page="help")

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)